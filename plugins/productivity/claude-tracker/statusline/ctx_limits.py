"""Per-model context-window limits for the statusline Ctx bar.

Family-substring match so new model IDs keep working without a code change.
Env override: CLAUDE_CTX_LIMIT=<int>.
"""
from __future__ import annotations

import os

CTX_LIMITS = {
    "opus": 1_000_000,
    "sonnet": 1_000_000,
    "haiku": 200_000,
}
DEFAULT_LIMIT = 200_000


def limit_for(model: str) -> int:
    override = os.environ.get("CLAUDE_CTX_LIMIT")
    if override:
        try:
            return int(override)
        except ValueError:
            pass
    m = (model or "").lower()
    for fam, lim in CTX_LIMITS.items():
        if fam in m:
            return lim
    return DEFAULT_LIMIT
