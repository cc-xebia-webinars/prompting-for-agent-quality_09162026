# FeeQuote demo kit

Everything the presenter needs, kept next to the demo repositories and never inside them, so an
agent working in a repository or one of its worktrees cannot read the expected answers.

Copy this folder to `~/demos/demo-kit`, next to the repositories (`~/demos/python-feequote` and
the others). The setup scripts and the commands in each script rely on that layout.

| Path | What it is |
|---|---|
| `<stack>/DEMO_SCRIPT.md` | The presenter's step-by-step script for that stack |
| `<stack>/prompts.txt` | Every prompt and command from the script, ready to paste |
| `<stack>/RUN_COMPARISON.md` | An optional record of run A against run B |
| `<stack>/setup-demo.sh`, `<stack>/setup-demo.ps1` | Build the demo git history in `../<stack>` |
| `<stack>/tier-check/` | The check for the model-tier demo (segment 4.3) |
| `run-stats.py` | Prints the run A and run B numbers for segment 4.5; run it from a repository folder as `python ../demo-kit/run-stats.py` (add `--vscode` for run B) |

Open `DEMO_SCRIPT.md` and `prompts.txt` on a monitor you do not share, not in the demo VS Code
window: an open editor tab is attached to chats as context.
