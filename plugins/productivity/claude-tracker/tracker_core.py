"""
Core tracker library — pure stdlib, no external deps.

Reused by:
  - statusline/claude-cost.sh (fast read-only summary)
  - skills/cost (on-demand detailed breakdown)
  - macos/menu_bar.py (ambient menu bar display)
  - hooks/stop-snapshot.sh (per-response snapshot write)

Run directly for a quick CLI summary:
  python3 tracker_core.py              # current-month summary
  python3 tracker_core.py --json       # JSON output
  python3 tracker_core.py --window     # current 5-hour window only
  python3 tracker_core.py --detail     # by model, by project
"""
from __future__ import annotations

import json
import os
import glob
import sys
import time
from dataclasses import dataclass, field, asdict
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any

HERE = Path(__file__).resolve().parent
PRICING_PATH = HERE / "pricing.json"

CLAUDE_DIR = Path(os.path.expanduser("~/.claude"))
CLAUDE_PROJECTS_DIR = CLAUDE_DIR / "projects"
CLAUDE_CREDENTIALS = CLAUDE_DIR / ".credentials.json"
OPENCODE_DIR = Path(os.path.expanduser("~/.local/share/opencode/log"))

WINDOW_HOURS = 5


# --- pricing --------------------------------------------------------------

@dataclass
class Pricing:
    models: dict[str, dict[str, float]]
    family_fallbacks: dict[str, dict[str, float]]
    default: dict[str, float]
    cache_write_mult: float
    cache_read_mult: float
    last_verified: str = ""

    @classmethod
    def load(cls, path: Path = PRICING_PATH) -> "Pricing":
        with open(path) as f:
            data = json.load(f)
        cm = data.get("cache_multipliers", {})
        return cls(
            models=data["models"],
            family_fallbacks=data.get("family_fallbacks", {}),
            default=data.get("default", {"input": 3.0, "output": 15.0}),
            cache_write_mult=cm.get("cache_write", 1.25),
            cache_read_mult=cm.get("cache_read", 0.1),
            last_verified=data.get("last_verified", ""),
        )

    def rates_for(self, model: str) -> dict[str, float]:
        if not model:
            return self.default
        if model in self.models:
            return self.models[model]
        for key, rates in self.models.items():
            if key in model or model in key:
                return rates
        m_low = model.lower()
        for fam, rates in self.family_fallbacks.items():
            if fam in m_low:
                return rates
        return self.default


# --- auth mode detection --------------------------------------------------

def detect_auth_mode() -> str:
    """
    Returns one of: api_key, subscription, unknown.

    Heuristic — does NOT read credential file contents:
      - ANTHROPIC_API_KEY env set   → api_key
      - ~/.claude/.credentials.json exists → subscription (OAuth login)
      - otherwise                   → unknown
    The tier (pro/max/team) is user-declared via the plugin config, since we
    can't derive it locally.
    """
    if os.environ.get("ANTHROPIC_API_KEY"):
        return "api_key"
    try:
        if CLAUDE_CREDENTIALS.exists() and CLAUDE_CREDENTIALS.stat().st_size > 0:
            return "subscription"
    except OSError:
        pass
    return "unknown"


# --- log entry parsing ----------------------------------------------------

@dataclass
class Usage:
    input_tokens: int = 0
    output_tokens: int = 0
    cache_creation_input_tokens: int = 0
    cache_read_input_tokens: int = 0

    def total_tokens(self) -> int:
        return (self.input_tokens + self.output_tokens
                + self.cache_creation_input_tokens + self.cache_read_input_tokens)

    def cost(self, rates: dict[str, float], cache_write_mult: float, cache_read_mult: float) -> float:
        inp = rates.get("input", 3.0)
        out = rates.get("output", 15.0)
        return (
            self.input_tokens / 1e6 * inp
            + self.output_tokens / 1e6 * out
            + self.cache_creation_input_tokens / 1e6 * inp * cache_write_mult
            + self.cache_read_input_tokens / 1e6 * inp * cache_read_mult
        )


@dataclass
class Entry:
    timestamp: datetime | None
    model: str
    usage: Usage
    project: str = ""


def _find_usage_and_model(obj: Any) -> tuple[dict | None, str]:
    if isinstance(obj, dict):
        if "usage" in obj and isinstance(obj["usage"], dict):
            model = obj.get("model") or obj.get("model_id") or ""
            if not model and "message" in obj and isinstance(obj["message"], dict):
                model = obj["message"].get("model", "")
            return obj["usage"], model
        for v in obj.values():
            found, model = _find_usage_and_model(v)
            if found is not None:
                if not model:
                    model = obj.get("model") or obj.get("model_id") or ""
                    if not model and "message" in obj and isinstance(obj["message"], dict):
                        model = obj["message"].get("model", "")
                return found, model
    elif isinstance(obj, list):
        for item in obj:
            found, model = _find_usage_and_model(item)
            if found is not None:
                return found, model
    return None, ""


def _parse_timestamp(raw: Any) -> datetime | None:
    if not raw:
        return None
    if isinstance(raw, (int, float)):
        try:
            return datetime.fromtimestamp(float(raw), tz=timezone.utc)
        except (ValueError, OSError):
            return None
    if not isinstance(raw, str):
        return None
    s = raw.replace("Z", "+00:00")
    try:
        return datetime.fromisoformat(s)
    except ValueError:
        for fmt in ("%Y-%m-%dT%H:%M:%S", "%Y-%m-%d %H:%M:%S"):
            try:
                return datetime.strptime(raw[:19], fmt).replace(tzinfo=timezone.utc)
            except ValueError:
                continue
    return None


def parse_line(line: str, project: str = "") -> Entry | None:
    line = line.strip()
    if not line:
        return None
    try:
        data = json.loads(line)
    except json.JSONDecodeError:
        return None

    usage_raw, model = _find_usage_and_model(data)
    if not usage_raw:
        return None

    ts = _parse_timestamp(
        data.get("timestamp") or data.get("created_at") or data.get("time")
    )
    u = Usage(
        input_tokens=int(usage_raw.get("input_tokens", 0) or 0),
        output_tokens=int(usage_raw.get("output_tokens", 0) or 0),
        cache_creation_input_tokens=int(usage_raw.get("cache_creation_input_tokens", 0) or 0),
        cache_read_input_tokens=int(usage_raw.get("cache_read_input_tokens", 0) or 0),
    )
    if u.total_tokens() == 0:
        return None
    return Entry(timestamp=ts, model=model or "", usage=u, project=project)


# --- log discovery --------------------------------------------------------

def _project_name_from_path(path: str) -> str:
    parts = Path(path).parts
    try:
        i = parts.index("projects")
        return parts[i + 1] if i + 1 < len(parts) else ""
    except ValueError:
        return ""


def discover_logs() -> list[tuple[str, str]]:
    """Return list of (filepath, project_name). project_name is '' for non-claude logs."""
    logs: list[tuple[str, str]] = []
    for fp in glob.glob(str(CLAUDE_DIR / "**" / "*.jsonl"), recursive=True):
        logs.append((fp, _project_name_from_path(fp)))
    for fp in glob.glob(str(OPENCODE_DIR / "*.log")):
        logs.append((fp, "opencode"))
    return logs


def iter_entries(since: datetime | None = None) -> list[Entry]:
    """Read all log files, filter by timestamp >= since (if provided)."""
    entries: list[Entry] = []
    since_epoch = since.timestamp() if since else 0.0
    for fp, project in discover_logs():
        try:
            if since and os.path.getmtime(fp) < since_epoch - 3600:
                continue
        except OSError:
            continue
        try:
            with open(fp, "r", errors="ignore") as f:
                for line in f:
                    e = parse_line(line, project=project)
                    if not e:
                        continue
                    if since and e.timestamp and e.timestamp < since:
                        continue
                    entries.append(e)
        except OSError:
            continue
    return entries


# --- aggregation ----------------------------------------------------------

@dataclass
class Summary:
    cost: float = 0.0
    tokens: dict[str, int] = field(default_factory=lambda: {
        "input": 0, "output": 0, "cache_write": 0, "cache_read": 0,
    })
    by_model: dict[str, float] = field(default_factory=dict)
    by_project: dict[str, float] = field(default_factory=dict)
    entry_count: int = 0

    def to_dict(self) -> dict:
        return asdict(self)


def summarize(entries: list[Entry], pricing: Pricing) -> Summary:
    s = Summary()
    for e in entries:
        rates = pricing.rates_for(e.model)
        c = e.usage.cost(rates, pricing.cache_write_mult, pricing.cache_read_mult)
        s.cost += c
        s.tokens["input"] += e.usage.input_tokens
        s.tokens["output"] += e.usage.output_tokens
        s.tokens["cache_write"] += e.usage.cache_creation_input_tokens
        s.tokens["cache_read"] += e.usage.cache_read_input_tokens
        model_key = e.model or "unknown"
        s.by_model[model_key] = s.by_model.get(model_key, 0.0) + c
        proj = e.project or "unknown"
        s.by_project[proj] = s.by_project.get(proj, 0.0) + c
        s.entry_count += 1
    return s


def month_start(now: datetime | None = None) -> datetime:
    now = now or datetime.now(timezone.utc)
    return datetime(now.year, now.month, 1, tzinfo=timezone.utc)


def window_start(now: datetime | None = None, hours: int = WINDOW_HOURS) -> datetime:
    now = now or datetime.now(timezone.utc)
    return now - timedelta(hours=hours)


# --- CLI ------------------------------------------------------------------

def _fmt_money(v: float, suffix: str = "") -> str:
    return f"${v:,.4f}{suffix}"


def _label_suffix(mode: str) -> str:
    return " equiv" if mode == "subscription" else ""


def _main() -> int:
    args = set(sys.argv[1:])
    pricing = Pricing.load()
    mode = detect_auth_mode()
    suffix = _label_suffix(mode)

    if "--window" in args:
        since = window_start()
        window_mode = True
    else:
        since = month_start()
        window_mode = False

    entries = iter_entries(since=since)
    summary = summarize(entries, pricing)

    if "--json" in args:
        out = summary.to_dict()
        out["auth_mode"] = mode
        out["since"] = since.isoformat()
        out["pricing_last_verified"] = pricing.last_verified
        print(json.dumps(out, indent=2))
        return 0

    scope = f"last {WINDOW_HOURS}h" if window_mode else datetime.now().strftime("%Y-%m")
    print(f"Scope: {scope} | auth: {mode} | entries: {summary.entry_count}")
    print(f"Cost: {_fmt_money(summary.cost, suffix)}")
    tok = summary.tokens
    print(
        f"Tokens — input: {tok['input']:,}  output: {tok['output']:,}  "
        f"cache_write: {tok['cache_write']:,}  cache_read: {tok['cache_read']:,}"
    )
    if "--detail" in args:
        print("\nBy model:")
        for k, v in sorted(summary.by_model.items(), key=lambda x: -x[1]):
            print(f"  {k or '(unknown)':<40} {_fmt_money(v, suffix)}")
        print("\nBy project:")
        for k, v in sorted(summary.by_project.items(), key=lambda x: -x[1]):
            print(f"  {k or '(unknown)':<40} {_fmt_money(v, suffix)}")
    if pricing.last_verified:
        age = (datetime.now().date() - datetime.strptime(pricing.last_verified, "%Y-%m-%d").date()).days
        if age > 90:
            print(f"\n⚠ pricing.json last verified {age}d ago — check anthropic.com/pricing")
    return 0


if __name__ == "__main__":
    sys.exit(_main())
