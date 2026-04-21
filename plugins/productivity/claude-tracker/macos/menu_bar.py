# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "rumps",
# ]
# ///
"""
macOS menu bar app — ambient cost display.

Reuses tracker_core for pricing, parsing, and pricing-correctness (cache tokens
included). Keeps local file_states so we only read new bytes per tick rather
than rescanning every file every 2 seconds.

Optional component of the claude-tracker plugin. The plugin's /cost skill and
statusline work without this.
"""
from __future__ import annotations

import json
import logging
import os
import sys
from datetime import datetime
from pathlib import Path

import rumps

HERE = Path(__file__).resolve().parent
PLUGIN_ROOT = HERE.parent
sys.path.insert(0, str(PLUGIN_ROOT))

import tracker_core as tc  # noqa: E402

DEBUG_LOG = os.path.expanduser("~/.claude_tracker.log")
CONFIG_FILE = os.path.expanduser("~/.claude_tracker_config.json")

logging.basicConfig(
    filename=DEBUG_LOG,
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
)


class ClaudeTrackerApp(rumps.App):
    def __init__(self) -> None:
        super().__init__("Claude")
        self.manual_offset = 0.0
        self.load_config()
        self.menu = ["Adjust Cost…", "Reset Cache", "View Log", "Quit"]

        self.pricing = tc.Pricing.load()
        self.auth_mode = tc.detect_auth_mode()
        self.suffix = "" if self.auth_mode == "api_key" else " eq"

        # {filepath: {'pos': int, 'month_cost': float, 'mtime': float}}
        self.file_states: dict[str, dict] = {}
        self.current_month_str = datetime.now().strftime("%Y-%m")

        logging.info(f"Claude Tracker started. auth_mode={self.auth_mode}")

        self.timer = rumps.Timer(self.update_display, 2)
        self.timer.start()
        self.update_display(None)

    # --- config persistence ---
    def load_config(self) -> None:
        if os.path.exists(CONFIG_FILE):
            try:
                with open(CONFIG_FILE) as f:
                    self.manual_offset = float(json.load(f).get("manual_offset", 0.0))
            except (OSError, ValueError, json.JSONDecodeError) as e:
                logging.error(f"Failed to load config: {e}")

    def save_config(self) -> None:
        try:
            with open(CONFIG_FILE, "w") as f:
                json.dump({"manual_offset": self.manual_offset}, f)
        except OSError as e:
            logging.error(f"Failed to save config: {e}")

    # --- incremental log reading ---
    def process_file(self, filepath: str, project: str, target_month: str) -> None:
        try:
            current_mtime = os.path.getmtime(filepath)
            current_size = os.path.getsize(filepath)
        except OSError as e:
            logging.error(f"Could not stat {filepath}: {e}")
            return

        state = self.file_states.setdefault(
            filepath, {"pos": 0, "month_cost": 0.0, "mtime": 0.0}
        )

        if current_mtime == state["mtime"] and current_size == state["pos"]:
            return
        if current_size < state["pos"]:
            # truncation / rotation — restart from 0
            state["pos"] = 0
            state["month_cost"] = 0.0
            logging.info(f"File reset detected: {filepath}")

        try:
            with open(filepath, "r", errors="ignore") as f:
                f.seek(state["pos"])
                for line in f:
                    entry = tc.parse_line(line, project=project)
                    if not entry:
                        continue
                    if entry.timestamp and entry.timestamp.strftime("%Y-%m") != target_month:
                        continue
                    rates = self.pricing.rates_for(entry.model)
                    state["month_cost"] += entry.usage.cost(
                        rates,
                        self.pricing.cache_write_mult,
                        self.pricing.cache_read_mult,
                    )
                state["pos"] = f.tell()
                state["mtime"] = current_mtime
        except OSError as e:
            logging.error(f"Error processing {filepath}: {e}")

    def update_display(self, _sender) -> None:
        now_month = datetime.now().strftime("%Y-%m")
        if now_month != self.current_month_str:
            logging.info(f"Month rollover: {self.current_month_str} -> {now_month}")
            self.current_month_str = now_month
            self.file_states = {}

        total = 0.0
        for fp, project in tc.discover_logs():
            try:
                if datetime.fromtimestamp(os.path.getmtime(fp)).strftime("%Y-%m") != now_month:
                    continue
            except OSError:
                continue
            self.process_file(fp, project, now_month)
            total += self.file_states.get(fp, {}).get("month_cost", 0.0)

        final = total + self.manual_offset
        self.title = f"Claude: ${final:.4f}{self.suffix}"

    # --- menu items ---
    @rumps.clicked("Adjust Cost…")
    def adjust_cost(self, _):
        window = rumps.Window(
            message=(
                f"Current manual offset: ${self.manual_offset:.4f}\n\n"
                "Enter amount to add (e.g. 1.50 or -0.50):"
            ),
            title="Manual Cost Adjustment",
            default_text="0.00",
            dimensions=(300, 20),
        )
        response = window.run()
        if not response.clicked:
            return
        try:
            self.manual_offset += float(response.text)
            self.save_config()
            self.update_display(None)
            logging.info(f"Manual offset updated: {self.manual_offset}")
        except ValueError:
            rumps.alert("Invalid number. Please enter a valid float (e.g. 0.50).")

    @rumps.clicked("Reset Cache")
    def reset_cache(self, _):
        self.file_states = {}
        self.update_display(None)
        logging.info("Cache manually reset by user.")

    @rumps.clicked("View Log")
    def view_log(self, _):
        if os.path.exists(DEBUG_LOG):
            os.system(f"open {DEBUG_LOG!r}")
        else:
            rumps.alert("No log file found yet.")


if __name__ == "__main__":
    ClaudeTrackerApp().run()
