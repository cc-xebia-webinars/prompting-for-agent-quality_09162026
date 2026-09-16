#!/usr/bin/env python3
"""Presenter-only: print the run A and run B comparison numbers for segment 4.5.

Copilot CLI keeps every session under ~/.copilot/session-state/<id>/events.jsonl, and
VS Code keeps chat sessions under its workspaceStorage folder, so the numbers are still
there after the run. This file lives in demos/demo-kit, outside every repository, so agents
never read it. Run it from the repository folder, before the next reset (the repository
numbers come from the working tree), for example in ~/demos/python-feequote:

    python ../demo-kit/run-stats.py               # run A: newest Copilot CLI session here
    python ../demo-kit/run-stats.py --vscode      # run B: newest VS Code chat session here
    python ../demo-kit/run-stats.py --git-only    # only the repository numbers
    python ../demo-kit/run-stats.py --session <id>    # one session (add --vscode for VS Code)

Only the Python standard library is used, so any Python 3.9 or newer works
(`python3` on macOS and Linux, `py` on Windows).
"""

from __future__ import annotations

import argparse
import contextlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from urllib.parse import unquote

READ_TOOLS = {"view"}
WRITE_TOOLS = {"edit", "create"}
SHELL_TOOLS = {"powershell", "bash", "shell", "local_shell"}
TEST_COMMAND = re.compile(
    r"pytest|vitest|npm (run )?test|npm run check|mvnw(\.cmd)?\b.*\b(test|verify)|dotnet test"
)
TEST_DECLARATION = re.compile(
    r"^\s*(def test_|async def test_|it\(|test\(|@Test\b|\[Fact|\[Theory)"
)
TEST_FILE = re.compile(
    r"(^|/)(tests?|__tests__)/|(Test|Tests)\.(java|cs)$|\.test\.(ts|tsx|js)$|(^|/)test_[^/]*\.py$"
)
FAILED = re.compile(
    r"\b[1-9]\d* failed\b|Tests?\s+[1-9]\d* failed|Failures: [1-9]|Errors: [1-9]"
    r"|BUILD FAILURE|failed: [1-9]|Failed!"
)
PASSED = re.compile(
    r"\b\d+ passed\b|Tests\s+\d+ passed|BUILD SUCCESS|Passed!|succeeded: \d+"
)
EXIT_CODE = re.compile(r"exit code (-?\d+)")
ARCHITECTURE = re.compile(r"architecture", re.IGNORECASE)
LEGACY_USE = re.compile(
    r"\bcalculate_fee\b|\bcalculateFee\b|\bCalculateFee\b|legacy[./]fees|Legacy\.Fees"
)
PRESENTER_FILES = re.compile(
    r"tier[-_]?check|RUN_COMPARISON|run-stats\.py", re.IGNORECASE
)


def normalized(path: str) -> str:
    return os.path.normcase(os.path.normpath(os.path.expanduser(path.strip())))


def relative(path: str) -> str:
    try:
        return os.path.relpath(path, os.getcwd()).replace("\\", "/")
    except ValueError:
        return path.replace("\\", "/")


def find_session(session_id: str | None) -> Path | None:
    root = (
        Path(os.environ.get("COPILOT_HOME", Path.home() / ".copilot")) / "session-state"
    )
    if not root.is_dir():
        return None
    if session_id:
        matches = sorted(root.glob(f"{session_id}*"))
        return matches[0] if matches else None
    here = normalized(os.getcwd())
    candidates = []
    for folder in root.iterdir():
        workspace, events = folder / "workspace.yaml", folder / "events.jsonl"
        if not (workspace.is_file() and events.is_file()):
            continue
        for line in workspace.read_text(
            encoding="utf-8", errors="replace"
        ).splitlines():
            if line.startswith("cwd:") and normalized(line[4:]) == here:
                candidates.append((events.stat().st_mtime, folder))
                break
    return max(candidates)[1] if candidates else None


def load_events(path: Path) -> list[dict]:
    events = []
    with path.open(encoding="utf-8", errors="replace") as handle:
        for line in handle:
            if line.strip():
                with contextlib.suppress(json.JSONDecodeError):
                    events.append(json.loads(line))
    return events


def test_verdict(output: str) -> str:
    if FAILED.search(output):
        return "failed"
    if PASSED.search(output):
        return "passed"
    code = EXIT_CODE.search(output)
    if code:
        return "passed" if code.group(1) == "0" else "failed"
    return "unclear"


def session_numbers(events: list[dict]) -> dict:
    numbers: dict = {
        "models": [],
        "turns": 0,
        "prompts": 0,
        "tool_calls": 0,
        "tools": {},
        "reads_before_edit": [],
        "files_written": [],
        "test_runs": [],
        "architecture_failed": False,
    }
    started: dict[str, dict] = {}
    edited = False
    shutdown = checkpoint = None
    for event in events:
        kind, data = event.get("type"), event.get("data") or {}
        if kind == "session.start" and data.get("selectedModel"):
            numbers["models"].append(data["selectedModel"])
        elif kind == "session.model_change":
            model = data.get("newModel") or data.get("model")
            if model and model not in numbers["models"]:
                numbers["models"].append(model)
        elif kind == "user.message":
            numbers["prompts"] += 1
        elif kind == "assistant.turn_start":
            numbers["turns"] += 1
        elif kind == "tool.execution_start":
            name = data.get("toolName", "?")
            arguments = data.get("arguments") or {}
            if isinstance(arguments, str):
                with contextlib.suppress(json.JSONDecodeError):
                    arguments = json.loads(arguments)
            if not isinstance(arguments, dict):
                arguments = {}
            numbers["tool_calls"] += 1
            numbers["tools"][name] = numbers["tools"].get(name, 0) + 1
            started[data.get("toolCallId", "")] = {"name": name, "arguments": arguments}
            path = arguments.get("path")
            if name in WRITE_TOOLS:
                edited = True
                if path and relative(path) not in numbers["files_written"]:
                    numbers["files_written"].append(relative(path))
            elif name in READ_TOOLS and not edited and path and not os.path.isdir(path):
                if relative(path) not in numbers["reads_before_edit"]:
                    numbers["reads_before_edit"].append(relative(path))
        elif kind == "tool.execution_complete" and not data.get("isUserRequested"):
            start = started.get(data.get("toolCallId", ""))
            if (
                not start
                or start["name"] not in SHELL_TOOLS
                or not data.get("success", True)
            ):
                continue
            if TEST_COMMAND.search(str(start["arguments"].get("command", ""))):
                output = str((data.get("result") or {}).get("content", ""))
                verdict = test_verdict(output)
                if verdict != "unclear":
                    numbers["test_runs"].append(verdict)
                if FAILED.search(output) and ARCHITECTURE.search(output):
                    numbers["architecture_failed"] = True
        elif kind == "session.shutdown":
            shutdown = data
        elif kind == "session.usage_checkpoint":
            checkpoint = data

    usage = shutdown or checkpoint or {}
    numbers["closed"] = shutdown is not None
    nano = usage.get("totalNanoAiu")
    numbers["credits"] = (
        round(nano / 1e9, 2) if isinstance(nano, (int, float)) else None
    )
    details = usage.get("tokenDetails") or {}
    numbers["tokens"] = {
        key: (details.get(source) or {}).get("tokenCount")
        for key, source in (
            ("input", "input"),
            ("cached", "cache_read"),
            ("cache write", "cache_write"),
            ("output", "output"),
        )
    }
    changes = usage.get("codeChanges") or {}
    if changes.get("filesModified"):
        numbers["files_written"] = [relative(p) for p in changes["filesModified"]]
    numbers["lines"] = (changes.get("linesAdded"), changes.get("linesRemoved"))
    requests = sum(
        ((metrics or {}).get("requests") or {}).get("count", 0)
        for metrics in (usage.get("modelMetrics") or {}).values()
    )
    numbers["model_requests"] = requests or None
    return numbers


VSCODE_READ_TOOLS = {"copilot_readFile"}
VSCODE_EDIT_TOOL = re.compile(
    r"replaceString|insertEdit|createFile|applyPatch|editNotebook", re.IGNORECASE
)
ANSWER_FILES = re.compile(
    r"(^|/)(demo-kit/|DEMO_SCRIPT\.md|RUN_COMPARISON\.md|prompts\.txt|tier-check/)"
)
EDITOR_STORAGE = re.compile(r"workspaceStorage|globalStorage", re.IGNORECASE)


def vscode_workspace_roots() -> list[Path]:
    home = Path.home()
    bases = [
        Path(os.environ.get("APPDATA", home / "AppData" / "Roaming")),
        home / "Library" / "Application Support",
        Path(os.environ.get("XDG_CONFIG_HOME", home / ".config")),
    ]
    names = ["Code", "Code - Insiders"]
    return [
        base / name / "User" / "workspaceStorage" for base in bases for name in names
    ]


def file_uri_path(uri: str) -> str:
    path = unquote(uri.removeprefix("file://"))
    if re.match(r"^/[A-Za-z]:", path):
        path = path[1:]
    return path


def find_vscode_session(session_id: str | None) -> Path | None:
    here = normalized(os.getcwd())
    candidates = []
    for root in vscode_workspace_roots():
        if not root.is_dir():
            continue
        for workspace in root.iterdir():
            meta = workspace / "workspace.json"
            sessions = workspace / "chatSessions"
            if not (meta.is_file() and sessions.is_dir()):
                continue
            with contextlib.suppress(OSError, json.JSONDecodeError):
                folder = json.loads(meta.read_text(encoding="utf-8")).get("folder", "")
                if (
                    not folder.startswith("file:")
                    or normalized(file_uri_path(folder)) != here
                ):
                    continue
                for session in sessions.glob("*.json*"):
                    if session_id is None or session.name.startswith(session_id):
                        candidates.append((session.stat().st_mtime, session))
    return max(candidates)[1] if candidates else None


def replay_vscode_session(path: Path) -> dict:
    """Rebuild a chat session: a snapshot line, then set (1) and append (2) patches."""
    text = path.read_text(encoding="utf-8", errors="replace")
    if path.suffix == ".json":
        return dict(json.loads(text))
    state: dict = {}
    for line in text.splitlines():
        if not line.strip():
            continue
        patch = json.loads(line)
        kind, keys, value = patch.get("kind"), patch.get("k") or [], patch.get("v")
        if kind == 0:
            state = value
            continue
        target = state
        for key in keys[:-1] if kind == 1 else keys:
            target = target[key]
        if kind == 1:
            target[keys[-1]] = value
        elif kind == 2:
            if patch.get("i") is not None:
                del target[patch["i"] :]
            target.extend(value)
    return state


def tool_uris(item: dict) -> list[str]:
    uris: list[str] = []
    for field in ("invocationMessage", "pastTenseMessage"):
        message = item.get(field)
        if isinstance(message, dict):
            uris.extend(u for u in (message.get("uris") or {}) if u.startswith("file:"))
    paths = (relative(file_uri_path(u).split("#")[0]) for u in uris)
    return list(dict.fromkeys(p for p in paths if not EDITOR_STORAGE.search(p)))


def vscode_numbers(state: dict) -> dict:
    numbers: dict = {
        "title": state.get("customTitle") or "",
        "requests": [],
        "tool_calls": 0,
        "subagent_tool_calls": 0,
        "tools": {},
        "reads_before_edit": [],
        "files_written": [],
        "test_commands": 0,
        "test_results": [],
        "architecture_failed": False,
        "questions": [],
    }
    edited = False
    for request in state.get("requests") or []:
        mode = request.get("modeInfo") or {}
        message = request.get("message") or {}
        numbers["requests"].append(
            {
                "mode": mode.get("name")
                or mode.get("telemetryModeName")
                or mode.get("kind")
                or "?",
                "model": str(request.get("modelId") or "?").removeprefix("copilot/"),
                "credits": request.get("copilotCredits"),
                "prompt_tokens": request.get("promptTokens"),
                "output_tokens": request.get("completionTokens"),
                "seconds": round((request.get("elapsedMs") or 0) / 1000),
                "text": str(
                    message.get("text", "") if isinstance(message, dict) else message
                ),
            }
        )
        for item in request.get("response") or []:
            if item.get("kind") != "toolInvocationSerialized":
                continue
            tool = str(item.get("toolId", "?"))
            numbers["tool_calls"] += 1
            numbers["subagent_tool_calls"] += (
                1 if item.get("subAgentInvocationId") else 0
            )
            numbers["tools"][tool] = numbers["tools"].get(tool, 0) + 1
            specific = item.get("toolSpecificData") or {}
            if VSCODE_EDIT_TOOL.search(tool):
                edited = True
                for path in tool_uris(item):
                    if path not in numbers["files_written"]:
                        numbers["files_written"].append(path)
            elif tool in VSCODE_READ_TOOLS and not edited:
                for path in tool_uris(item):
                    if path not in numbers["reads_before_edit"]:
                        numbers["reads_before_edit"].append(path)
            elif tool == "vscode_askQuestions":
                invocation = item.get("invocationMessage") or {}
                label = (
                    invocation.get("value")
                    if isinstance(invocation, dict)
                    else invocation
                )
                numbers["questions"].append(str(label))
            elif tool == "run_in_terminal":
                command = str((specific.get("commandLine") or {}).get("original", ""))
                numbers["test_commands"] += 1 if TEST_COMMAND.search(command) else 0
            if specific.get("kind") == "subagent" and TEST_COMMAND.search(
                str(specific)
            ):
                result = str(specific.get("result", ""))
                verdict = test_verdict(result)
                if verdict != "unclear":
                    numbers["test_results"].append(verdict)
                if FAILED.search(result) and ARCHITECTURE.search(result):
                    numbers["architecture_failed"] = True
    return numbers


def print_vscode(path: Path, numbers: dict) -> None:
    requests = numbers["requests"]
    credits = [r["credits"] for r in requests if isinstance(r["credits"], (int, float))]
    tools = sorted(numbers["tools"].items(), key=lambda item: -item[1])
    print(
        f"VS Code chat session {path.stem}"
        + (f": {numbers['title']}" if numbers["title"] else "")
    )
    models = list(dict.fromkeys(r["model"] for r in requests))
    print(f"- Model: {', '.join(models) or 'n/a'}")
    reads = numbers["reads_before_edit"]
    print(f"- Files read before the first edit: {len(reads)}{listed(reads)}")
    warn_answer_files(reads)
    print(f"- Requests (turns you started): {len(requests)}")
    for index, r in enumerate(requests, start=1):
        credit = (
            f"{r['credits']:.1f} credits"
            if isinstance(r["credits"], (int, float))
            else "n/a"
        )
        print(
            f"    {index}. {r['mode']}, {credit}, prompt tokens {number(r['prompt_tokens'])},"
            f" output tokens {number(r['output_tokens'])}, {r['seconds']}s: {r['text'][:50]!r}"
        )
    subagents = numbers["subagent_tool_calls"]
    print(
        f"- Tool calls: {numbers['tool_calls']} ({subagents} inside subagents)"
        f"{listed([f'{k} {v}' for k, v in tools])}"
    )
    questions = numbers["questions"]
    print(
        f"- Clarifying questions asked: {'yes' if questions else 'no'}{listed(questions)}"
    )
    results = numbers["test_results"]
    summary = f", subagent results: {', '.join(results)}" if results else ""
    print(f"- Test commands run in the terminal: {numbers['test_commands']}{summary}")
    architecture = "yes" if numbers["architecture_failed"] else "no (or not reported)"
    print(f"- Architecture test failed at some point: {architecture}")
    written = numbers["files_written"]
    print(f"- Files the agent edited: {len(written)}{listed(written)}")
    total = f"{sum(credits):.1f}" if credits else "n/a"
    print(f"- AI credits: {total} (the sum of the requests above)")


def git(*args: str) -> str:
    try:
        return subprocess.run(
            ["git", *args], capture_output=True, text=True, check=False
        ).stdout
    except OSError:
        return ""


def repository_numbers() -> dict:
    status = git("status", "--porcelain", "--untracked-files=all").splitlines()
    changed = [line[3:].strip().strip('"') for line in status if line.strip()]
    changed = [path for path in changed if not PRESENTER_FILES.search(path)]
    tests_added = 0
    legacy: list[str] = []
    current = ""
    for line in git("diff", "HEAD", "-U0", "--no-color").splitlines():
        if line.startswith("+++ "):
            current = line[6:] if line.startswith("+++ b/") else ""
        elif line.startswith("+") and current and not PRESENTER_FILES.search(current):
            if TEST_DECLARATION.search(line[1:]):
                tests_added += 1
            uses_legacy = LEGACY_USE.search(line[1:]) and not current.endswith(".md")
            if uses_legacy and current not in legacy:
                legacy.append(current)
    for path in git("ls-files", "--others", "--exclude-standard").splitlines():
        if TEST_FILE.search(path) and not PRESENTER_FILES.search(path):
            with contextlib.suppress(OSError):
                text = Path(path).read_text(encoding="utf-8", errors="replace")
                tests_added += sum(
                    1 for row in text.splitlines() if TEST_DECLARATION.search(row)
                )
    return {"changed": changed, "tests_added": tests_added, "legacy": legacy}


def number(value: object) -> str:
    return "n/a" if value is None else f"{value:,}"


def listed(items: list[str]) -> str:
    return f" ({', '.join(items)})" if items else ""


def warn_answer_files(paths: list[str]) -> None:
    seen = [path for path in paths if ANSWER_FILES.search(path)]
    if seen:
        print(
            f"  WARNING: the agent read presenter files{listed(seen)}. They hold the expected"
        )
        print("  answers, so this run is not a fair sample.")


def print_session(folder: Path, numbers: dict) -> None:
    open_note = (
        "" if numbers["closed"] else " (still open: credits so far, tokens after /exit)"
    )
    runs = numbers["test_runs"]
    tools = sorted(numbers["tools"].items(), key=lambda item: -item[1])
    lines_changed = numbers["lines"]
    print(f"Copilot CLI session {folder.name}{open_note}")
    print(f"- Model: {', '.join(numbers['models']) or 'n/a'}")
    reads = numbers["reads_before_edit"]
    print(f"- Files read before the first edit: {len(reads)}{listed(reads)}")
    warn_answer_files(reads)
    print(
        f"- Turns: {numbers['turns']} (model requests: {number(numbers['model_requests'])},"
        f" prompts you typed: {numbers['prompts']})"
    )
    print(
        f"- Tool calls: {numbers['tool_calls']}{listed([f'{k} {v}' for k, v in tools])}"
    )
    if runs:
        print(
            f"- Test runs by the agent: {len(runs)} (first: {runs[0]}, last: {runs[-1]})"
        )
    else:
        print("- Test runs by the agent: 0")
    architecture = "yes" if numbers["architecture_failed"] else "no"
    print(f"- Architecture test failed at some point: {architecture}")
    written = numbers["files_written"]
    size = (
        f", +{lines_changed[0]} -{lines_changed[1]} lines"
        if lines_changed[0] is not None
        else ""
    )
    print(f"- Files the agent edited: {len(written)}{listed(written)}{size}")
    tokens = ", ".join(
        f"{key} {number(value)}" for key, value in numbers["tokens"].items()
    )
    print(f"- Tokens: {tokens}")
    print(f"- AI credits: {number(numbers['credits'])}")


def main() -> int:
    parser = argparse.ArgumentParser(description=(__doc__ or "").splitlines()[0])
    parser.add_argument(
        "--session", help="session id (default: newest session in this folder)"
    )
    parser.add_argument(
        "--vscode", action="store_true", help="read the VS Code chat session"
    )
    parser.add_argument(
        "--git-only", action="store_true", help="only the repository numbers"
    )
    args = parser.parse_args()

    if args.vscode and not args.git_only:
        chat = find_vscode_session(args.session)
        if chat is None:
            print(
                "No VS Code chat session found for this folder. Run this from the folder that"
            )
            print(
                "is open in VS Code, or pass --session <id> (a file name under chatSessions)."
            )
            return 1
        print_vscode(chat, vscode_numbers(replay_vscode_session(chat)))
    elif not args.git_only:
        folder = find_session(args.session)
        if folder is None:
            print(
                "No Copilot CLI session found for this folder. Run this from the folder you"
            )
            print(
                "started copilot in, or pass --session <id> from the 'Resume' line at /exit."
            )
            return 1
        print_session(folder, session_numbers(load_events(folder / "events.jsonl")))

    repo = repository_numbers()
    print("Repository (working tree against the last commit)")
    print(f"- Files touched: {len(repo['changed'])}{listed(repo['changed'])}")
    print(f"- Tests added: {repo['tests_added']}")
    print(f"- Legacy helper used in added code: {', '.join(repo['legacy']) or 'no'}")
    print(
        "Not covered: the quote total (run the quote check) and the suite now (run the tests)."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
