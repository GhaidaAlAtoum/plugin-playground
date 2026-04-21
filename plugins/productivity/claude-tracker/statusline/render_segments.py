#!/usr/bin/env python3
"""Renderer for ccstatusline's Custom Command widget.

CLI: render_segments.py --segment {ctx|block|month}

Reads Claude Code session JSON from stdin, emits one ANSI-colored segment.
Never blocks: expensive scans run in a detached background refresher, and
the foreground path always returns either cached values or a dim placeholder.
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import tempfile
import time
from datetime import datetime, timedelta, timezone
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))  # import tracker_core
sys.path.insert(0, str(HERE))         # import ctx_limits

import tracker_core as tc  # noqa: E402
import ctx_limits  # noqa: E402

CACHE_DIR = Path(os.environ.get("TMPDIR", "/tmp"))
CACHE_FILE = CACHE_DIR / "claude-tracker-status.v2.json"
LOCK_FILE = CACHE_DIR / "claude-tracker-status.v2.lock"

BLOCK_TTL = 30     # seconds
MONTH_TTL = 120    # seconds

BAR_WIDTH = 10
FILL = "▓"    # ▓
EMPTY = "░"   # ░

ANSI_RESET = "\x1b[0m"
ANSI_DIM = "\x1b[2m"
ANSI_GREEN = "\x1b[32m"
ANSI_YELLOW = "\x1b[33m"
ANSI_RED = "\x1b[31m"


# --- bar rendering --------------------------------------------------------

def _color_for_pct(pct: float) -> str:
    if pct >= 0.90:
        return ANSI_RED
    if pct >= 0.70:
        return ANSI_YELLOW
    return ANSI_GREEN


def render_bar(pct: float) -> str:
    pct = max(0.0, min(1.0, pct))
    filled = round(pct * BAR_WIDTH)
    color = _color_for_pct(pct)
    return f"{color}{FILL * filled}{EMPTY * (BAR_WIDTH - filled)}{ANSI_RESET}"


def render_bar_dim() -> str:
    return f"{ANSI_DIM}{EMPTY * BAR_WIDTH}{ANSI_RESET}"


# --- formatting helpers ---------------------------------------------------

def _fmt_tokens(n: int) -> str:
    if n >= 1_000_000:
        v = n / 1_000_000
        return f"{v:.1f}M" if v < 10 else f"{int(round(v))}M"
    if n >= 1_000:
        return f"{int(round(n / 1_000))}K"
    return str(n)


def _fmt_limit(n: int) -> str:
    if n >= 1_000_000 and n % 1_000_000 == 0:
        return f"{n // 1_000_000}M"
    if n >= 1_000 and n % 1_000 == 0:
        return f"{n // 1_000}K"
    return _fmt_tokens(n)


def _fmt_remaining(seconds: float) -> str:
    s = max(0, int(seconds))
    if s <= 0:
        return "expired"
    h, rem = divmod(s, 3600)
    m = rem // 60
    if h > 0:
        return f"{h}h{m:02d}m left"
    if m >= 1:
        return f"{m}m left"
    return "<1m left"


def _fmt_time_to_reset(seconds: float) -> str:
    s = max(0, int(seconds))
    if s <= 0:
        return "resetting now"
    h, rem = divmod(s, 3600)
    m = rem // 60
    if h > 0:
        return f"{h}h{m:02d}m to reset"
    if m >= 1:
        return f"{m}m to reset"
    return "<1m to reset"


def _eq_suffix(auth_mode: str) -> str:
    return " eq" if auth_mode == "subscription" else ""


# --- cache ---------------------------------------------------------------

def _now_epoch() -> float:
    return time.time()


def _read_cache() -> dict:
    try:
        with open(CACHE_FILE, "r") as f:
            return json.load(f) or {}
    except (OSError, json.JSONDecodeError):
        return {}


def _write_cache(data: dict) -> None:
    try:
        CACHE_DIR.mkdir(parents=True, exist_ok=True)
        fd, tmp = tempfile.mkstemp(dir=str(CACHE_DIR), prefix=".tracker-v2.")
        with os.fdopen(fd, "w") as f:
            json.dump(data, f)
        os.replace(tmp, CACHE_FILE)
    except OSError:
        pass


def _is_fresh(sub: dict | None, ttl: int) -> bool:
    if not isinstance(sub, dict):
        return False
    ts = sub.get("ts", 0)
    return (_now_epoch() - ts) < ttl


def _maybe_spawn_refresh(cache: dict) -> None:
    """If block or month is stale and no lock, detach a background refresh.
    Never blocks the foreground render.
    """
    block_stale = not _is_fresh(cache.get("block"), BLOCK_TTL)
    month_stale = not _is_fresh(cache.get("month"), MONTH_TTL)
    if not (block_stale or month_stale):
        return
    if LOCK_FILE.exists():
        return
    # Fork a detached child that re-invokes ourselves with --refresh.
    try:
        pid = os.fork()
    except OSError:
        return
    if pid != 0:
        # Parent — don't wait.
        return
    try:
        os.setsid()
    except OSError:
        pass
    # Detach stdio so we don't hold the statusline pipe.
    devnull = os.open(os.devnull, os.O_RDWR)
    os.dup2(devnull, 0)
    os.dup2(devnull, 1)
    os.dup2(devnull, 2)
    try:
        _refresh()
    finally:
        os._exit(0)


def _refresh() -> None:
    """Background path: do the expensive scans and update the cache."""
    try:
        LOCK_FILE.touch()
    except OSError:
        return
    try:
        cache = _read_cache()
        auth = tc.detect_auth_mode()
        pricing = tc.Pricing.load()
        now = datetime.now(timezone.utc)

        # Block: walk ~24h of entries to catch a fresh block after quiet time.
        since_24h = now - timedelta(hours=24)
        entries_24h = tc.iter_entries(since=since_24h)
        bw = tc.block_window(entries_24h, now=now)
        if bw is not None:
            start, end = bw
            block_entries = [e for e in entries_24h
                             if e.timestamp and e.timestamp >= start]
            s_block = tc.summarize(block_entries, pricing)
            cache["block"] = {
                "ts": _now_epoch(),
                "start": start.isoformat(),
                "end": end.isoformat(),
                "cost": s_block.cost,
                "auth_mode": auth,
            }

        # Month: month-to-date aggregate.
        entries_month = tc.iter_entries(since=tc.month_start(now))
        s_month = tc.summarize(entries_month, pricing)
        cache["month"] = {
            "ts": _now_epoch(),
            "cost": s_month.cost,
            "auth_mode": auth,
        }
        _write_cache(cache)
    finally:
        try:
            LOCK_FILE.unlink()
        except OSError:
            pass


# --- segments -------------------------------------------------------------

def _parse_stdin() -> dict:
    raw = sys.stdin.read() if not sys.stdin.isatty() else ""
    if not raw.strip():
        return {}
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return {}


def _stringify_model(raw) -> str:
    """Claude Code sends `model` as a dict like
    {"id": "claude-opus-4-7", "display_name": "Opus 4.7"}. Also tolerate
    a plain string in case that ever changes."""
    if isinstance(raw, dict):
        return raw.get("id") or raw.get("display_name") or ""
    if isinstance(raw, str):
        return raw
    return ""


def segment_ctx(payload: dict) -> str:
    transcript = payload.get("transcript_path", "")
    stdin_model = _stringify_model(payload.get("model"))
    result = tc.last_assistant_context_tokens(transcript) if transcript else None
    if result is None:
        return f"Ctx {render_bar_dim()} {ANSI_DIM}??%{ANSI_RESET}"
    tokens, transcript_model = result
    # Prefer stdin model — it reflects the currently-active session model.
    # Fall back to transcript's last-turn model if stdin didn't provide one.
    limit = ctx_limits.limit_for(stdin_model or transcript_model)
    pct = tokens / limit if limit else 0.0
    bar = render_bar(pct)
    return (
        f"Ctx {bar} {pct * 100:.0f}% "
        f"({_fmt_tokens(tokens)}/{_fmt_limit(limit)})"
    )


def segment_block(cache: dict) -> str:
    block = cache.get("block")
    if not isinstance(block, dict) or "start" not in block:
        return (
            f"5h {render_bar_dim()} "
            f"{ANSI_DIM}—:—{ANSI_RESET} "
            f"· {ANSI_DIM}$—.——{ANSI_RESET}"
        )
    try:
        start = datetime.fromisoformat(block["start"])
        end = datetime.fromisoformat(block["end"])
    except (TypeError, ValueError):
        return f"5h {render_bar_dim()}"
    now = datetime.now(timezone.utc)
    total = (end - start).total_seconds()
    elapsed = (now - start).total_seconds()
    pct = elapsed / total if total > 0 else 1.0
    remaining = (end - now).total_seconds()
    bar = render_bar(pct)
    cost = float(block.get("cost", 0.0))
    suffix = _eq_suffix(block.get("auth_mode", ""))
    return f"5h {bar} {_fmt_time_to_reset(remaining)} · ${cost:,.2f}{suffix}"


def segment_session(payload: dict) -> str:
    transcript = payload.get("transcript_path", "")
    if not transcript:
        return f"\U0001f4ac {ANSI_DIM}Session $—.——{ANSI_RESET}"
    pricing = tc.Pricing.load()
    s = tc.transcript_summary(transcript, pricing)
    suffix = _eq_suffix(tc.detect_auth_mode())
    return f"\U0001f4ac Session ${s.cost:,.2f}{suffix}"


def segment_month(cache: dict) -> str:
    month = cache.get("month")
    if not isinstance(month, dict) or "cost" not in month:
        return f"{ANSI_DIM}\U0001f4b0 $—.—— mo{ANSI_RESET}"
    cost = float(month["cost"])
    suffix = _eq_suffix(month.get("auth_mode", ""))
    return f"\U0001f4b0 ${cost:,.2f}{suffix} mo"


# --- main -----------------------------------------------------------------

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--segment", choices=("ctx", "block", "session", "month"))
    ap.add_argument("--refresh", action="store_true",
                    help="Internal: run the background refresher synchronously.")
    args = ap.parse_args()

    if args.refresh:
        _refresh()
        return 0

    if not args.segment:
        ap.print_usage()
        return 2

    payload = _parse_stdin()

    if args.segment == "ctx":
        # Ctx is computed live per-render — no cache dependency.
        sys.stdout.write(segment_ctx(payload))
        return 0

    if args.segment == "session":
        # Session cost is live per-render — reads only the current transcript.
        sys.stdout.write(segment_session(payload))
        return 0

    cache = _read_cache()
    _maybe_spawn_refresh(cache)
    if args.segment == "block":
        sys.stdout.write(segment_block(cache))
    else:
        sys.stdout.write(segment_month(cache))
    return 0


if __name__ == "__main__":
    sys.exit(main())
