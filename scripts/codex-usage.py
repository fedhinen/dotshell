#!/usr/bin/env python3
"""Return cached Codex rate-limit information as privacy-safe JSON."""

from __future__ import annotations

import datetime as dt
import fcntl
import json
import os
from pathlib import Path
import select
import shutil
import signal
import subprocess
import sys
import time
from typing import Any, Iterator


CACHE_MAX_AGE_SECONDS = 30 * 60
REQUEST_TIMEOUT_SECONDS = 15
SCHEMA_VERSION = 1


def now_iso() -> str:
    return dt.datetime.now().astimezone().isoformat(timespec="seconds")


def cache_paths() -> tuple[Path, Path]:
    cache_root = Path(
        os.environ.get("XDG_CACHE_HOME", str(Path.home() / ".cache"))
    ) / "chillpill-shell"
    cache_root.mkdir(mode=0o700, parents=True, exist_ok=True)
    try:
        cache_root.chmod(0o700)
    except OSError:
        pass
    return cache_root / "codex-usage.json", cache_root / "codex-usage.lock"


def load_cache(path: Path) -> dict[str, Any] | None:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        return data if data.get("schemaVersion") == SCHEMA_VERSION else None
    except (OSError, ValueError, TypeError):
        return None


def cache_is_fresh(data: dict[str, Any] | None) -> bool:
    if not data or not data.get("updatedAt"):
        return False
    try:
        updated = dt.datetime.fromisoformat(data["updatedAt"])
        return (dt.datetime.now().astimezone() - updated).total_seconds() < CACHE_MAX_AGE_SECONDS
    except (TypeError, ValueError):
        return False


def save_cache(path: Path, data: dict[str, Any]) -> None:
    temporary = path.with_suffix(".tmp")
    temporary.write_text(
        json.dumps(data, ensure_ascii=False, separators=(",", ":")) + "\n",
        encoding="utf-8",
    )
    temporary.chmod(0o600)
    os.replace(temporary, path)


def logged_in(codex: str) -> bool:
    try:
        result = subprocess.run(
            [codex, "login", "status"],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=5,
            check=False,
        )
        return result.returncode == 0
    except (OSError, subprocess.TimeoutExpired):
        return False


def message_stream(
    process: subprocess.Popen[bytes], deadline: float
) -> Iterator[dict[str, Any]]:
    assert process.stdout is not None
    buffer = b""
    while time.monotonic() < deadline:
        timeout = max(0, deadline - time.monotonic())
        readable, _, _ = select.select([process.stdout], [], [], timeout)
        if not readable:
            break
        chunk = os.read(process.stdout.fileno(), 4096)
        if not chunk:
            break
        buffer += chunk
        while b"\n" in buffer:
            line, buffer = buffer.split(b"\n", 1)
            try:
                yield json.loads(line)
            except (UnicodeDecodeError, ValueError):
                continue
    raise TimeoutError("Codex App Server did not respond in time")


def request_rate_limits(codex: str) -> dict[str, Any]:
    process: subprocess.Popen[bytes] = subprocess.Popen(
        [codex, "app-server", "--listen", "stdio://"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        bufsize=0,
        start_new_session=True,
    )
    deadline = time.monotonic() + REQUEST_TIMEOUT_SECONDS
    messages = message_stream(process, deadline)

    def send(payload: dict[str, Any]) -> None:
        if process.stdin is None:
            raise RuntimeError("Codex App Server stdin is unavailable")
        process.stdin.write(
            (json.dumps(payload, separators=(",", ":")) + "\n").encode("utf-8")
        )
        process.stdin.flush()

    try:
        send({
            "id": 1,
            "method": "initialize",
            "params": {
                "clientInfo": {
                    "name": "chillpill-shell",
                    "title": "Chillpill dashboard",
                    "version": "1",
                },
                "capabilities": None,
            },
        })

        while True:
            message = next(messages)
            if message.get("id") == 1:
                if "error" in message:
                    raise RuntimeError("Codex App Server initialization failed")
                break

        send({"method": "initialized"})
        send({"id": 2, "method": "account/rateLimits/read", "params": None})

        while True:
            message = next(messages)
            if message.get("id") == 2:
                if "error" in message:
                    raise RuntimeError("Codex rate-limit request failed")
                return message.get("result") or {}
    finally:
        if process.poll() is None:
            try:
                os.killpg(process.pid, signal.SIGTERM)
                process.wait(timeout=2)
            except (OSError, subprocess.TimeoutExpired):
                try:
                    os.killpg(process.pid, signal.SIGKILL)
                except OSError:
                    pass


def weekly_window(result: dict[str, Any]) -> dict[str, Any] | None:
    snapshots: list[dict[str, Any]] = []
    historical = result.get("rateLimits")
    if isinstance(historical, dict):
        snapshots.append(historical)
    by_id = result.get("rateLimitsByLimitId")
    if isinstance(by_id, dict):
        snapshots.extend(value for value in by_id.values() if isinstance(value, dict))

    windows: list[dict[str, Any]] = []
    for snapshot in snapshots:
        for key in ("primary", "secondary"):
            window = snapshot.get(key)
            if isinstance(window, dict) and isinstance(window.get("usedPercent"), int):
                windows.append(window)

    if not windows:
        return None
    return max(windows, key=lambda item: item.get("windowDurationMins") or 0)


def fresh_payload(result: dict[str, Any]) -> dict[str, Any]:
    window = weekly_window(result)
    if not window:
        raise RuntimeError("Codex did not return a rate-limit window")

    used = max(0, min(100, int(window["usedPercent"])))
    reset_timestamp = window.get("resetsAt")
    reset_iso = None
    if isinstance(reset_timestamp, int):
        reset_iso = dt.datetime.fromtimestamp(
            reset_timestamp, tz=dt.timezone.utc
        ).astimezone().isoformat(timespec="seconds")

    return {
        "schemaVersion": SCHEMA_VERSION,
        "loggedIn": True,
        "consumedPercent": used,
        "remainingPercent": 100 - used,
        "resetsAt": reset_iso,
        "windowMinutes": window.get("windowDurationMins"),
        "updatedAt": now_iso(),
        "stale": False,
        "error": None,
    }


def error_payload(previous: dict[str, Any] | None, message: str, is_logged_in: bool) -> dict[str, Any]:
    data = dict(previous or {})
    data.update({
        "schemaVersion": SCHEMA_VERSION,
        "loggedIn": is_logged_in,
        "updatedAt": now_iso(),
        "stale": True,
        "error": message,
    })
    if not is_logged_in:
        data.update({
            "consumedPercent": None,
            "remainingPercent": None,
            "resetsAt": None,
            "windowMinutes": None,
        })
    return data


def main() -> int:
    cache_path, lock_path = cache_paths()
    with lock_path.open("a+", encoding="utf-8") as lock:
        fcntl.flock(lock.fileno(), fcntl.LOCK_EX)
        cached = load_cache(cache_path)
        if cache_is_fresh(cached):
            print(json.dumps(cached, ensure_ascii=False, separators=(",", ":")))
            return 0

        codex = shutil.which("codex")
        if not codex:
            data = error_payload(cached, "Codex CLI no está instalado", False)
        else:
            is_logged_in = logged_in(codex)
            if not is_logged_in:
                data = error_payload(cached, "Inicia sesión en Codex", False)
            else:
                try:
                    data = fresh_payload(request_rate_limits(codex))
                except (OSError, RuntimeError, TimeoutError, ValueError):
                    data = error_payload(cached, "No se pudo actualizar Codex", True)

        save_cache(cache_path, data)
        print(json.dumps(data, ensure_ascii=False, separators=(",", ":")))
        return 0


if __name__ == "__main__":
    sys.exit(main())
