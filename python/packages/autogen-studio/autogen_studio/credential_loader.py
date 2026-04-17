"""Credential loading helpers for local AutoGen Studio examples."""

from __future__ import annotations

import os
from pathlib import Path


def load_api_key(env_var: str = "OPENAI_API_KEY", dotenv_path: str = ".env") -> str:
    """Load an API key from environment first, then fallback to a .env file.

    The .env fallback supports `KEY=value` lines and ignores empty/comment lines.
    """
    value = os.environ.get(env_var)
    if value:
        return value

    env_file = Path(dotenv_path)
    if env_file.is_file():
        for raw_line in env_file.read_text().splitlines():
            line = raw_line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, candidate = line.split("=", 1)
            if key.strip() == env_var and candidate.strip():
                return candidate.strip().strip('"').strip("'")

    raise RuntimeError(
        f"Missing required credential: {env_var}. Set it in the environment or {dotenv_path}."
    )
