# FeeQuote demo script (Python)

This is the presenter's step-by-step script. Every demo runs live. Every block of text in a
grey box is meant to be copied and pasted exactly as written.

## How to read this script

Each segment starts with a short summary:

- **Where:** which tool you use (VS Code Copilot Chat, Copilot CLI, or a plain terminal).
- **Branch:** which git branch must be checked out.
- **What this shows:** the one idea the audience should take away.

Then come numbered steps. Each step has the same parts, in the same order:

- **Do:** what to click or type.
- **Paste:** the exact prompt or command.
- **Expected:** what a correct result looks like for that exact prompt.
- **Point at:** what to show the audience on screen.
- **Say:** one line to deliver.

Some steps are preceded by an **Ask** line: a prediction question you put to the
attendees before the step runs. They answer in chat, and you read out the spread of answers
when the result is on screen.

Each segment ends with **If something goes wrong** and **Where this shows up in real
repositories** (common patterns to mention, not specific incidents).

Terms used throughout:

- **Terminal** means a window of your terminal app, in the repository folder, with the
  virtual environment activated:
  - **macOS:** Terminal or iTerm2 (zsh or bash).
  - **Linux:** your usual terminal (bash or zsh).
  - **Windows:** Windows Terminal running PowerShell 7 (`pwsh`). Windows PowerShell 5.1 is
    not enough: several commands below chain with `&&`, which 5.1 cannot parse.
- **Commands** are the same on all three systems unless the script shows a separate
  **macOS and Linux** block and a **Windows** block. Paths are written as `~/demos/...`; in
  PowerShell `~` is your user folder too, so `cd ~/demos/python-feequote` works everywhere.
- **Two terminals side by side:** iTerm2, split with Cmd+D. macOS Terminal, open a second
  window with Cmd+N and put the two windows side by side. Windows Terminal, split with
  Alt+Shift+D. Linux, two windows side by side (or your terminal's split command).
- **Copilot CLI session** means you typed `copilot` in a terminal and are at its prompt.
  Inside a session, a line that starts with `!` runs as a shell command, and a line that
  starts with `/` is a Copilot CLI command. **Run every Copilot CLI session in your terminal
  app, not in the VS Code integrated terminal**: VS Code can take Ctrl+O, Ctrl+E and Ctrl+T
  for its own commands, and segment 4.10 needs them. Those three shortcuts use Ctrl on macOS
  too, not Cmd.
- **Finished** means the agent has stopped working: in the CLI the prompt comes back with no
  spinner; in VS Code the Stop button in the chat box turns back into Send.
- **Share the demo display**, the whole monitor with VS Code and your terminal app on it, not
  one window: the demos move between the two. Keep this script, your prompts file and your
  notes on a second monitor that is **not** shared, because the script contains the expected
  answers and the prediction outcomes.

## Prerequisites and setup (do this the day before)

1. Install git, VS Code with the GitHub Copilot and Copilot Chat extensions, Copilot CLI and
   uv (<https://docs.astral.sh/uv/>). You do not need a system Python; uv downloads one.
   - **macOS:** `brew install git uv` and `brew install --cask copilot-cli` (and the Xcode command line tools if git
     asks for them).
   - **Linux:** git from your package manager, `curl -LsSf https://astral.sh/uv/install.sh | sh`,
     and `npm install -g @github/copilot`.
   - **Windows:** `winget install Git.Git astral-sh.uv GitHub.Copilot Microsoft.PowerShell`.
2. Copy two folders out of any synchronized folder (OneDrive, iCloud Drive, Dropbox) into
   `~/demos` (on Windows that is `C:\Users\<you>\demos`), side by side: the `python-feequote`
   repository and the `demo-kit` folder. The repository holds only the demo code. `demo-kit`
   holds this script, `prompts.txt`, `RUN_COMPARISON.md`, the setup scripts, the segment 4.3
   check and `run-stats.py`, outside the repository, so no agent can read them. The commands
   below assume `~/demos/python-feequote` and `~/demos/demo-kit`; if yours differ, change
   `~/demos` wherever it appears.
3. In a terminal in that folder, run:

   macOS and Linux:

   ```bash
   uv venv --python 3.14
   uv pip install -r requirements-dev.txt
   bash ../demo-kit/python-feequote/setup-demo.sh
   ```

   Windows:

   ```powershell
   uv venv --python 3.14
   uv pip install -r requirements-dev.txt
   ..\demo-kit\python-feequote\setup-demo.ps1
   ```

   If Windows blocks the script, run
   `pwsh -ExecutionPolicy Bypass -File ..\demo-kit\python-feequote\setup-demo.ps1`.

   The setup script creates this history:

   | Name | What it is |
   |---|---|
   | `demo-start` branch, tag `v0.1.0` | The code with no Copilot customization files. Used by segments 4.2, 4.3 and 4.5. |
   | `main` branch, tag `v0.2.0` | The same code plus instruction files, the reviewer agent, the release-notes skill and MCP configuration. Used by 4.7, 4.9 and 4.10. |
   | `demo-checks` branch, tag `demo-checks-base` | `main` plus one commit with a defect the tests do not catch but ruff and mypy do. Used by 4.7. The tag lets you restore the branch after an experiment. |

   Nothing from `demo-kit` is in the repository, so no branch or worktree contains it and the
   resets never touch it. Open this script from `~/demos/demo-kit/python-feequote` on the
   unshared monitor, not in the demo VS Code window: it contains the expected answers, and an
   open editor tab is attached to chats as context.

4. Activate the virtual environment in the terminal you will run Copilot from, and leave it
   activated:

   macOS and Linux:

   ```bash
   source .venv/bin/activate
   ```

   Windows:

   ```powershell
   .\.venv\Scripts\Activate.ps1
   ```

   This matters. `AGENTS.md` tells the agent to run `python -m pytest -q`, `ruff check .`
   and `mypy feequote tests` by itself. Outside the virtual environment, macOS and Linux
   usually have no `python` command at all (only `python3`, without the test tools), and
   Windows resolves `python` to the Microsoft Store stub, so the agent's checks fail for a
   reason that has nothing to do with the lesson.

5. Check everything is green:

   ```bash
   python -m pytest -q
   ruff check .
   mypy feequote tests
   ```

   Expected: `57 passed`, `All checks passed!`, and `Success: no issues found`.

6. Open the folder in VS Code. Select the `.venv` interpreter when asked (so the integrated
   terminal activates it). On `main`, confirm the Copilot Chat agent picker lists `reviewer`.

7. Every prompt and command in this script is already in
   `~/demos/demo-kit/python-feequote/prompts.txt`, in the order you need them, so nothing is
   typed live. Open it in a plain text editor on the unshared monitor (TextEdit on macOS,
   Notepad on Windows, any text editor on Linux), **not** in the demo VS Code window, where an
   open file is attached to chats. `prompts.txt` has no expected answers; those stay in this
   script. It lives outside the repository, so the resets below never touch it.

8. Set up the segment 4.3 worktrees for one stack at a time: every stack uses the same
   `~/demos/feequote-lower` and `~/demos/feequote-higher` folders.

9. Check that no personal instruction files are active (for example
   `~/.copilot/copilot-instructions.md`, or instructions in your VS Code profile). They would
   be sent with every request and blur the comparison between run A and run B.

## Reset between rehearsals

**In VS Code first:** discard any pending agent edits (**Undo** on the chat's changed-files
list), run **View: Close All Editors**, and clear or archive old chats. Pending edits and open
editors can write old content back to disk after a git reset.

Then type `/exit` in every open Copilot CLI session and close the two segment 4.3 terminals
(Windows cannot remove a worktree folder that a running program is using). Then run these in a
terminal in the repository folder:

```bash
git worktree remove --force ../feequote-lower
git worktree remove --force ../feequote-higher
git checkout -q -f main && git reset -q --hard v0.2.0 && git clean -fdq
git branch -f demo-checks demo-checks-base
git checkout -q -B demo-start v0.1.0
uv pip install -r requirements-dev.txt
git status --short
git worktree list
python -m pytest -q; ruff check .; mypy feequote tests
```

`git status --short` must print nothing and `git worktree list` must show one line. The two
`worktree remove` lines print an error if the worktrees do not exist; that is fine. If they
print "Permission denied" instead, a session is still open in that folder: close it and run the
line again. If a worktree folder still remains, delete it and run `git worktree prune`. The
last line must print `57 passed`, `All checks passed!` and `Success: no issues found`; if an
agent installed or removed packages and something fails, recreate the environment with `uv venv
--python 3.14 --clear` and `uv pip install -r requirements-dev.txt`.

To repeat segment 4.3 in the existing worktrees, see "Run it again" in that segment.

**Live reset (during the session, when the 4.3 worktrees may still exist):**

```bash
git checkout -q -f demo-start && git reset -q --hard v0.1.0 && git clean -fdq
```

To throw away one experiment without resetting branches: `git checkout -- . && git clean -fdq`.

Only if the history itself is damaged: `bash ../demo-kit/python-feequote/setup-demo.sh --force`
(Windows: `..\demo-kit\python-feequote\setup-demo.ps1 -Force`) rebuilds it. It refuses to run
unless `main` is checked out at `v0.2.0`, clean and has no extra worktrees, so close VS Code and
every Copilot CLI session, run the full reset above, then `git checkout -q main` first.

---

## Segment 4.2: context window

- **Where:** VS Code Copilot Chat, then Copilot CLI.
- **Branch:** `demo-start`.
- **What this shows:** attached files cost tokens before the model writes a word, and a rule
  stated early in a session is only as durable as the conversation that carries it.

**Before you start:** VS Code is open on the repository, with no editors open. In a terminal,
run the live reset:

```bash
cd ~/demos/python-feequote
git checkout -q -f demo-start && git reset -q --hard v0.1.0 && git clean -fdq
git status --short
```

**Expected:** `git status --short` prints nothing.

**Ask** the attendees, who answer in chat: "Guess the token count for the five attached files
before the first reply comes back."

### Step 1: VS Code, ask a question that needs five files

**Do:** open Copilot Chat (Ctrl+Cmd+I on macOS, Ctrl+Alt+I on Windows and Linux). Start a new chat
with the **+** button. In the agent picker at the bottom of the chat box, choose **Agent** (and, if the chat box
also shows a target picker, choose **Local**).
Hover the context window control in the chat box so the audience sees the token count
before you send anything.

**Paste:**

```
#file:README.md #file:feequote/core/pricing.py #file:feequote/legacy/fees.py #file:feequote/services/transfer_service.py #file:tests/test_transfer_service.py
Which fee helper should new code call, and why? Answer from the code, not the README.
```

**Expected:** the answer should say, in its own words:

- New code should call `compute_fee(amount_cents)` for the domestic fee, or
  `price_with_policy(amount_cents, rate_bps, policy)` for any other fee, both in
  `feequote/core/pricing.py`.
- New code should **not** call `calculate_fee` in `feequote/legacy/fees.py`, because it
  truncates instead of rounding half to even and ignores the minimum and the cap.
- The README is out of date: it recommends `calculate_fee`.
- Evidence: `test_regression_ticket_4821` in `tests/test_transfer_service.py` expects a fee
  of 1112 for 123500 cents, where the legacy helper would return 1111.

**Point at:**

1. The token count in the context window control going up after you send, before the answer
   appears. The five files are input tokens.
2. In the answer, the sentence saying the README is wrong, and the test name it quotes as
   evidence.

**Say:** "The tests and the core pricing module contradict the README. That disagreement is
what the rest of today's demos are built around."

### Step 2: Copilot CLI, state a rule, then compact

**Do:** in your terminal app, in the repository folder, type `copilot` and press Enter. Answer
the folder trust prompt if it appears. Type `/model` and pick the higher-tier model, because
the model chosen in an earlier session may still be selected.

**Paste** (the CLI attaches files with `@`, not `#file:`):

```
@README.md @feequote/core/pricing.py @feequote/legacy/fees.py @feequote/services/transfer_service.py @tests/test_transfer_service.py
Read these files. For the rest of this session, end every answer with a final line that starts with "Sources:" and lists the files you used. For now, just reply OK.
```

**Expected:** a short reply ending in `OK`, possibly with a `Sources:` line.

**Paste:**

```
/context
```

**Expected:** a breakdown of the context window by category (System Prompt, Custom
Instructions, System Tools, MCP Tools, Messages, Free Space, Buffer). The five attached files
are part of **Messages**.

**Point at:** the size of the Messages share. This is what every later turn resends.

**Ask** the attendees, who answer in chat: "I've told the agent to end every answer with a
Sources: line. Will that rule survive /compact? Type yes or no."

**Paste:**

```
/compact
```

**Expected:** a message that the conversation was summarized.

**Paste:**

```
/context
```

**Expected:** the Messages share is much smaller; a summary replaced the attached files.

**Paste:**

```
Which tests fail if new code calls the legacy fee helper instead of core pricing?
```

**Expected:** the answer names `test_regression_ticket_4821` in
`tests/test_transfer_service.py` (1112 expected, the legacy helper gives 1111) and
`tests/test_architecture.py` (it fails when new code references `calculate_fee`).

**Point at:** the last line of that answer. Does it still start with `Sources:`?

**Say**, if the `Sources:` line is there: "The summary happened to keep my rule this time. I
did nothing to make sure it would."

**Say**, if it is missing: "Compaction summarized the rule away. That is context rot, sped up
for the demo."

**Say**, either way: "A rule typed at the start of a session competes with everything that
comes after it, and the most recent text usually wins. A rule in an instruction file is sent
again with every single request. We come back to that in module 4."

Type `/exit` to close this CLI session; nothing else needs it.

### If something goes wrong

- The token count is not visible in VS Code: skip that point and use `/context` in the CLI,
  which always shows the breakdown.
- Running long: skip the second `/context` and go straight from `/compact` to the follow-up
  question.
- Do not try to make context rot happen over many turns live. The `/compact` check is the
  demo.

### Extra prompts (optional, only if an attendee asks for more)

```
Where is the domestic fee cap defined, and which tests cover it?
```

Expected: `DOMESTIC_POLICY` in `feequote/core/pricing.py` (cap 2500 cents), covered by
`test_domestic_policy_values` and `test_compute_fee_worked_examples` in
`tests/test_pricing.py`.

```
Walk me through how a quote is assembled, one file at a time, without proposing any changes.
```

### Where this shows up in real repositories

- A README or wiki page that describes how the code worked two years ago, while the tests
  describe how it works today.
- Long agent sessions where an instruction given early ("do not change the public API") is
  ignored many turns later.

---

## Segment 4.3: model tier

- **Where:** two Copilot CLI sessions side by side, one on a lower-tier model and one on a
  higher-tier model.
- **Branch:** `demo-start`, in two separate git worktrees so the two runs cannot interfere.
- **What this shows:** a lower tier is fine for mechanical work, but on a task where the
  right answer depends on thinking through consequences, it writes code that looks right,
  passes every existing test, and charges a customer twice.

**Before the session (preparation, at the end of the T-60 checks, after the full reset in
"Reset between rehearsals" near the top):**

1. In a terminal in the repository folder:

   ```bash
   git worktree add --detach ../feequote-lower demo-start
   git worktree add --detach ../feequote-higher demo-start
   ```

2. Open two new terminals side by side (see "Two terminals side by side" at the top). New
   terminals start in your home folder, so use full paths. In the left one:

   macOS and Linux:

   ```bash
   cd ~/demos/feequote-lower
   source ~/demos/python-feequote/.venv/bin/activate
   ```

   Windows:

   ```powershell
   cd ~/demos/feequote-lower
   ~/demos/python-feequote/.venv/Scripts/Activate.ps1
   ```

   In the right one, the same with `feequote-higher` in place of `feequote-lower`.
3. In both terminals type `copilot --allow-all-tools` and answer the folder trust prompt. The
   worktrees are disposable copies, so allowing all tools here only saves approval prompts
   that would otherwise stall the runs while you talk.
4. In the left session, type `/model` and pick a lower-tier model (a small, cheap model on
   your account's list). In the right one, pick a higher-tier model (for example
   `claude-sonnet-5` or stronger). Write both model names in the rehearsal checklist.

**The trap (presenter only).** Finding the retry helper is easy: `with_retry` sits next to
the client in `feequote/clients/retry.py`. What matters is *where* the retry goes. Every
submission carries an idempotency key, and the gateway treats submissions that share a key as
one payment. `PaymentClient.submit` calls `_send`, which mints a fresh key and calls the
transport in one line:

```python
def _send(self, transfer: Transfer) -> str:
    return self._transport(transfer, new_idempotency_key())
```

The obvious change, `with_retry(lambda: self._send(transfer))`, mints a new key on every
attempt. When the gateway takes the payment but the response is lost (a `GatewayTimeoutError`),
the retry becomes a second payment. The correct change mints the key once, before the retry,
and retries only `GatewayTimeoutError` (a `GatewayDeclinedError` is final). Both versions pass
the existing suite. The check in
`~/demos/demo-kit/python-feequote/tier-check/test_tier_check.py` (outside the repository, so no
agent can see it) tells them apart.

**Ask** the attendees, who answer in chat: "When a gateway response is lost, will the cheaper
model's retry charge the customer once or twice? Type once or twice."

### Step 1: both CLI sessions, start the same design task

**Do:** paste the prompt into the lower-tier session and press Enter, then immediately paste
it into the higher-tier session and press Enter.

**Paste** (into both):

```
Add retry with exponential backoff to the payment client submit path
```

**Expected:** both agents find `with_retry` and edit `feequote/clients/payment_client.py`, and
both report green tests. Typically:

- The **lower tier** either wraps the `_send` call, so every attempt gets a new idempotency
  key, or mints the key once but retries every `GatewayError`, so a declined transfer is sent
  three times. It sometimes commits its change as well.
- The **higher tier** notices that `_send` mints the key, hoists the key out of the retry,
  retries only `GatewayTimeoutError`, and usually adds tests for both cases.

This is a tendency, not a guarantee. In a Copilot CLI trial with 4 runs per model on this
repository, all 4 `claude-haiku-4.5` runs failed the Step 2 check (2 charged twice, 2 sent a
declined transfer three times) and all 4 `claude-opus-5` runs passed it. Each Haiku run used
5 to 8 AI credits and each Opus run 47 to 68.

**Point at:** while they run, whether each one reads `_send` and says anything about the
idempotency key before its first edit.

If the runs are still going when it is time for checkpoint 1, leave them running and come
back to Step 2 straight after the checkpoint.

### Step 2: both CLI sessions, check which run gets a payment wrong

**Paste** (into both, after each run finishes):

```
!cp ../demo-kit/python-feequote/tier-check/test_tier_check.py tests/ && python -m pytest -q --tb=line tests/test_tier_check.py
```

**Expected:** three tests against a fake gateway that deduplicates on the idempotency key.

| Test | What it checks | Plain wrap of `_send` | Key minted once |
|---|---|---|---|
| `test_recovers_when_the_gateway_times_out_once` | a retry exists | passes | passes |
| `test_charges_the_customer_once_when_a_response_is_lost` | the gateway took the payment, the response was lost | **fails**: `customer charged 2 times for tr-4300 (keys: ..., ...)` | passes |
| `test_does_not_resubmit_a_declined_transfer` | a decline is final | **fails** if every `GatewayError` is retried: `declined transfer sent 3 times` | passes |

Read out whichever failure appears: `customer charged 2 times`, with two different keys, or
`declined transfer sent 3 times` (the count follows the run's number of attempts), which
resubmits a payment the bank already refused. A run can
show both. On an untouched
`demo-start` the first two tests fail with `GatewayTimeoutError`, because nothing retries yet.

**Paste** (into both):

```
/usage
```

**Expected:** each session's model, tokens and usage.

**Point at:** the two usage screens side by side, and the check result in each.
Then read out how the attendees answered in chat.

**Say:** "Both versions passed every test the repository had. One of them charges a customer
twice on a network blip. The price difference between tiers is small next to one
duplicate-payment incident."

### Step 3 (optional, only if ahead of time): the mechanical task on the lower tier

**Do:** in the lower-tier session, discard the previous change first with
`!git reset -q --hard demo-start && git clean -fdq` (this also undoes a commit, if the run
made one).

**Paste:**

```
Rename `compute_fee` to `domestic_fee` across the code and tests, keep a deprecated alias for one release
```

**Expected:** `domestic_fee` defined in `feequote/core/pricing.py`, callers updated in
`feequote/services/transfer_service.py` and `tests/test_pricing.py`, and an alias
`compute_fee = domestic_fee` with a deprecation note. The checks still pass.

**Say:** "Mechanical, well specified, easy to verify: this is where the lower tier earns its
price."

### Run it again (rehearsal, or a second take)

Use this to repeat Steps 1 and 2 without removing the worktrees, for example to see how often
the lower tier gets it wrong.

**Do:** in each of the two sessions, reset the worktree to `demo-start`. This discards the
agent's edits, any commit it made, and the copied check file. The virtual environment lives in the main repository folder, so nothing needs reinstalling.

**Paste** (into both):

```
!git reset -q --hard demo-start && git clean -fdq
```

**Expected:** no output. `!git status --short` then prints nothing, and `!git log --oneline -1`
shows the `demo-start` commit.

**Do:** type `/clear` in both sessions, so neither agent remembers its previous attempt. Type
`/model` and confirm the left session is still on the lower tier and the right one on the
higher tier. Then go back to Step 1.

From a plain terminal instead, with both sessions closed:

```bash
git -C ~/demos/feequote-lower reset -q --hard demo-start && git -C ~/demos/feequote-lower clean -fdq
git -C ~/demos/feequote-higher reset -q --hard demo-start && git -C ~/demos/feequote-higher clean -fdq
```

### Step 4: close both sessions

**Do:** type `/exit` in both sessions and close both terminals. The worktrees stay on disk
until the full reset removes them (the two `git worktree remove` lines in "Reset between
rehearsals"), but nothing may still be running inside them.

### If something goes wrong

- Both tiers charge once: say so, and show the `_send` line. Ask the audience which one word in
  the prompt ("idempotent") would make a cheaper model reliable here. An honest result is more
  convincing than a staged one, and the usage comparison still stands.
- Both tiers charge twice: point at `_send` and ask what would have caught it: a plan that
  names where the key is minted, or a review point. That is segment 4.5.
- A run is very slow: move on and read its check and `/usage` after checkpoint 1.

### Where this shows up in real repositories

- Duplicate payments, emails or orders because a retry was wrapped around a call that is not
  idempotent, or around the code that mints the idempotency key.

---

## Segment 4.5: run A and run B

- **Where:** run A in Copilot CLI (standard mode). Run B in VS Code with the Plan agent.
- **Branch:** `demo-start`, reset before each run.
- **What this shows:** the same model, with and without a plan and a review point, on a task
  where the README points at the wrong helper.

Both runs use the **same higher-tier model**, so the only difference is the plan.

The feature prompt, used unchanged for both runs:

```
Add support for international transfers. A transfer is international when the destination country differs from the origin country. International transfers incur an additional FX fee of 50 basis points of the amount, subject to the same minimum, cap, and rounding policy as the domestic fee. The quote must show the FX fee as its own line in the breakdown and include it in the total. Acceptance examples: a 247100 cent international transfer quotes a domestic fee of 2224, an FX fee of 1236, and a total fee of 3460. A 1000000 cent international transfer quotes 2500 domestic, 2500 FX, total 5000. A domestic transfer is unchanged. Add tests for these examples and run the full test suite.
```

**What correct and incorrect look like:**

| | Uses core pricing (correct) | Uses the legacy helper (the trap) |
|---|---|---|
| Helper called | `price_with_policy(amount_cents, 50, DOMESTIC_POLICY)` | `calculate_fee(amount_cents, 50)` for the FX fee, and sometimes for the domestic fee too |
| 247100 cents | 2224 + 1236 = **3460** | 2224 + 1235 = 3459 (FX fee only on the legacy helper), or 2223 + 1235 = 3458 (both) |
| 1000000 cents | 2500 + 2500 = **5000** | 2500 + 5000 = 7500 (FX fee uncapped), or 9000 + 5000 = 14000 (both, with no cap at all) |
| `tests/test_architecture.py` | passes | fails with the ticket 4821 message |

### Step 1: Copilot CLI, run A

**Before you start:** make sure both segment 4.3 sessions are closed (Step 4 above). In VS
Code, open Copilot Chat, start a new chat with **+**, pick **Plan** in the agent picker and the
higher-tier model, and leave it ready for run B. Then, in your terminal app, run the live reset
and start the CLI:

```bash
cd ~/demos/python-feequote
git checkout -q -f demo-start && git reset -q --hard v0.1.0 && git clean -fdq
git status --short
copilot
```

`git status --short` must print nothing before `copilot` starts. In the session, press
Shift+Tab until the mode shown is the standard one (not plan, not autopilot; write the exact
label in the rehearsal checklist). Type `/model` and pick the higher-tier model.

**Ask** the attendees, who answer in chat: "Which fee helper will it pick? Type calculate_fee,
compute_fee, or price_with_policy."

**Do:** paste the feature prompt. Approve tool calls as they come.

**Say** as you paste: "The FX fee is 50 basis points. One basis point is a hundredth of a
percent, so that is half a percent."

**Expected:** a run that trusts the README uses `calculate_fee`, gets a total other than 3460
and 5000 (usually 3459 and 7500), and then hits a failing `tests/test_architecture.py`. It may then take extra turns, change
numbers by hand, or edit a test.

**Point at, while it runs:**

1. The files it opens before its first edit. Did it read `tests/test_transfer_service.py`
   or `tests/test_architecture.py` first?
2. Whether it imports from `feequote/legacy/fees.py`.

**Check when it finishes** (paste into the session):

```
!python -m feequote quote --amount 247100 --from AU --to NZ
```

**Expected:** a JSON quote. The correct answer is `"fee_cents": 3460` with a separate FX line
in `breakdown`. `3459` or `3458` means it used the legacy helper.

```
/usage
```

**Do:** type `/exit`. Copilot CLI prints a short summary (changes, AI credits, tokens) and a
`Resume` line. Nothing is lost: every session stays saved on disk. Then, in the same terminal
and **before the live reset** (the repository numbers come from run A's changes), print run A's
numbers for the comparison:

```bash
python ../demo-kit/run-stats.py
```

**Expected:** a short list: model, files read before the first edit (with their names), turns,
tool calls, the agent's test runs (first and last result), whether the architecture test failed
at some point, files the agent edited, tokens, AI credits, and from the repository the files
touched, tests added and whether added code uses the legacy helper. Copy it into
`RUN_COMPARISON.md` or onto paper. The total comes from the quote check above.

**Hard stop:** if run A is still working six minutes after you pasted the prompt, press Esc,
run the quote check on whatever it has, and say that the rework is still going: that is the
point.

### Step 2: VS Code, run B

**Before you start:** make sure run A's numbers are printed (end of Step 1): the reset below
discards run A's changes. Then run the live reset again, in the same terminal:

```bash
cd ~/demos/python-feequote
git checkout -q -f demo-start && git reset -q --hard v0.1.0 && git clean -fdq
git status --short
```

`git status --short` must print nothing. In VS Code, run **View: Close All Editors** (an open
file is attached to the chat as context and would bias the run), then switch to the Plan chat
you opened before run A. Check that it still shows **Plan** and the higher-tier model.

**Ask** the attendees, who answer in chat: "Will the plan cost more or fewer credits than run
A? Type more or fewer."

**Do:** paste the same feature prompt. Read the plan it produces on screen.

**Expected plan:** it mentions the ticket 4821 regression test and/or the architecture test,
and says to use `price_with_policy` with `DOMESTIC_POLICY` and a 50 basis point rate.

**If the plan names `calculate_fee`:** type one correction, for example "Use
price_with_policy from core pricing, not the legacy helper; see tests/test_architecture.py",
and let it revise the plan.

**Do:** click **Start Implementation**, choose the implementation agent it offers (Agent), and
approve tool calls.

**Expected:** the tests for 3460 and 5000 are added and the full suite passes the first time.

**Check when it finishes** (in the VS Code terminal):

```bash
python -m feequote quote --amount 247100 --from AU --to NZ
```

**Expected:** `"fee_cents": 3460`.

**Hard stop:** if run B has not finished eight minutes after you pasted the prompt, stop it, read
the plan aloud and point at the helper it chose; the plan is the part of run B the comparison
depends on.

**Do:** before segment 4.7 resets the repository, print run B's numbers in the VS Code
terminal (repository folder). VS Code saves every chat session on disk, and the script reads
the newest one for this folder:

```bash
python ../demo-kit/run-stats.py --vscode
```

**Expected:** the same kind of list as run A's: model, files read before the first edit, one
line per request (the Plan request, then the implementation, then any follow-up) with its
credits, tokens and time, tool calls (including those inside subagents), clarifying questions,
test runs, files edited, total AI credits, and the repository numbers. The total comes from
the quote check above.

If it prints `WARNING: the agent read presenter files`, the run saw the expected answers in
`DEMO_SCRIPT.md` or `RUN_COMPARISON.md`: say so when you compare, and delete any copy of those
files from the repository folder before the next rehearsal. Without Python, hover the context window
control in the chat box for credits and tokens, and expand the collapsed tool call groups to
count the files read before the first edit.

### Step 3: compare the two runs aloud

Stay on the run B slide; there is no results slide. Read today's live numbers aloud: run A's from the `run-stats.py` output in the terminal app,
and run B's from the `run-stats.py --vscode` output in the VS Code terminal: model;
files read before
the first edit; correct totals (3460 and 5000); tests added for both examples; full suite
green the first time; architecture test green; checks run; legacy helper avoided; files
touched; turns and tool calls; tokens; credits.

**Say**, if run B cost more credits than run A: "The plan spent credits reading before
writing. Run A spent them writing twice. The number to look at is files read before the first
edit."

**Say**, either way: "Both runs used the same model tier, so the main thing that changed was
where the review point sat."

If you kept a rehearsal tally in `RUN_COMPARISON.md`, read it next. The live run is one
sample; the tally is the evidence.

### If something goes wrong

- Run A gets the right answer: say it was lucky this time, then read run A's
  numbers from the rehearsal tally in `RUN_COMPARISON.md`, which shows how often it fails.
- Run B's plan is right but an implementation step fails a check: say this is exactly what
  the check loop in module 4 is for, and let the agent fix it.

### Where this shows up in real repositories

- A half-finished migration: the old helper is still there for a batch job, it has the most
  convenient signature, and the docs still point at it.

---

## Segment 4.7: guardrails and instruction files

- **Where:** Copilot CLI, then VS Code.
- **Branch:** `demo-checks` for Steps 1 and 2, then `main` for Steps 3 to 5.
- **What this shows:** tests, linters and type checkers are feedback the agent can run
  itself, and an instruction file is what makes it run them.

**Before you start:** in VS Code, discard run B's pending edits (**Undo** on the chat's
changed-files list) and run **View: Close All Editors**. In your terminal app, in the
repository folder:

```bash
git checkout -q -f main && git reset -q --hard v0.2.0 && git clean -fdq
git checkout -q -f demo-checks
git status --short
```

`git status --short` must print nothing. Start the session with the three check commands
allowed, so the run does not stop for an approval on each one:

```bash
copilot --allow-tool "shell(python:*)" --allow-tool "shell(ruff:*)" --allow-tool "shell(mypy:*)"
```

Then type `/model` and pick the higher-tier model.

### Step 1: Copilot CLI, the tests are green

**Paste:**

```
!python -m pytest -q
```

**Expected:** `57 passed`.

**Paste:**

```
!python -m feequote quote --amount 500000 --from AU --to AU
```

**Expected:** a JSON quote showing `"fee_cents": 2500.0`, with a decimal point.

**Point at:** every test passes, yet the quote shows a fee of `2500.0`. Money in this code base
is meant to be whole cents.

### Step 2: Copilot CLI, let the checks find it

**Paste:**

```
Run every check listed in AGENTS.md and fix whatever they report. Do not change any tests.
```

**Expected:** the agent runs three commands and finds two problems, both in
`feequote/core/pricing.py`:

- `ruff check .` reports ``F401 [*] `math` imported but unused`` at
  `feequote/core/pricing.py:10:8`.
- `mypy feequote tests` reports `Argument "cap_cents" to "FeePolicy" has incompatible type
  "float"; expected "int"` (line 35, `cap_cents=2500.0`).

It removes `import math`, changes `2500.0` to `2500`, and runs all three checks again: green.

**Point at:** the ruff and the mypy output. Neither problem failed a test.

**Say:** "Green tests are not the same as done. The type checker catches a wrong type; it
would not catch run A's wrong helper, because that had a valid signature. You need both."

**Do:** discard the fix and move to `main`:

```
!git checkout -q -f main
```

**Do:** start a fresh Copilot CLI session. The previous session still carries "Do not change
any tests", which would fight the next task, where changing tests is correct. Type `/exit`,
then, in the same terminal, start the session again with the check commands allowed:

```bash
copilot --allow-tool "shell(python:*)" --allow-tool "shell(ruff:*)" --allow-tool "shell(mypy:*)"
```

Then type `/model` and pick the higher-tier model.

### Step 3: Copilot CLI, change a requirement and watch the loop

**Ask** the attendees, who answer in chat: "Will the agent run the test suite without being
told to? Type yes or no."

**Paste:**

```
Change the domestic cap to 3000 cents and update everything that depends on it
```

**Expected:** the agent changes `DOMESTIC_POLICY` in `feequote/core/pricing.py`, runs the
test suite without being asked, and may see up to three failures (it may also update some
tests before it runs them):

- `test_compute_fee_worked_examples[cap applies]` in `tests/test_pricing.py` (expects 2500)
- `test_domestic_policy_values` in `tests/test_pricing.py` (expects 2500)
- `test_quote_applies_minimum_and_cap` in `tests/test_transfer_service.py`

It updates the expected values to 3000 and runs the checks again until they pass.

**Point at:** the moment the agent runs `python -m pytest -q` on its own. Nothing in the
prompt asked it to.

**Say:** "Updating expected test values is legitimate here, because the requirement changed:
the cap is now 3000. In run A it was not legitimate, because the requirement had not
changed."

**Leave this change uncommitted.** Segment 4.9 reviews it.

### Step 4: VS Code, show the files that made it happen

**Do:** in VS Code, open the Agent Customizations editor (the gear icon in the Chat view, or
run **Chat: Open Customizations** from the Command Palette). If it is not available, open the
files from the Explorer. If the editor does not list the reviewer agent or the instruction
files, run **Developer: Reload Window** once: VS Code may not have noticed the `.github` folder
coming back when the branch changed. Show these three files:

- `.github/copilot-instructions.md`: point first at the line "Run the full test suite, the
  linter, and the type checker before declaring a task complete. A task with failing checks
  is not done." That is the rule you just watched the agent follow. Then read the legacy
  helper line aloud: with it in place, run A would not have gone the way it did.
- `.github/instructions/tests.instructions.md`: point at `applyTo: "tests/**"` at the top.
  These rules load only when test files are involved.
- `AGENTS.md`: the short version, with the exact three commands.

### Step 5: Copilot CLI, ask history for improvements

**Paste:**

```
/chronicle improve
```

**Expected:** suggestions for the instruction files based on past sessions in this
repository.

**Point at:** any suggestion that repeats a correction you gave the agent more than once.

**Do:** type `/exit` to close this CLI session. Segment 4.9 starts in VS Code.

### If something goes wrong

- The agent does not run the suite in Step 3: ask `Is this task complete?` and point at the
  line in `.github/copilot-instructions.md`. If it still does not run the checks, paste
  `!python -m pytest -q` yourself and read the failures aloud.
- The agent changes a test in Step 2: point out that the prompt said not to, and that this is
  exactly the behavior the instruction file and review exist to catch.
- `/chronicle improve` has nothing to say: explain that it needs a few sessions of history
  in this repository to learn from, and move on.
- Running long: skip Step 5 (`/chronicle improve`) first; it is the first thing to cut in this
  segment.

### Where this shows up in real repositories

- Money stored as floating point, or a dead import, that passes every test and ships because
  nobody ran the linter or type checker in CI.
- Tests that still encode an old business rule after the rule changed, and an agent (or a
  person) that cannot tell a changed requirement from a bug.

---

## Segment 4.9: custom agent, skill, MCP and subagents

- **Where:** VS Code Copilot Chat, then Copilot CLI, then back to VS Code.
- **Branch:** `main`, with the uncommitted cap change from segment 4.7 still in the working
  tree.
- **What this shows:** one set of files in the repository drives agents, skills and tools on
  both surfaces, and a subagent keeps a big read-only job out of the main conversation.

**Before you start:** confirm `git status` shows the cap change from segment 4.7. If it does
not, edit `feequote/core/pricing.py` and set `cap_cents=3000` without touching the tests.

Prepare two terminals side by side while the previous slides are up: the **left terminal**
is a plain terminal in the repository folder (the one from segment 4.7). Open the **right
terminal** next to it. New terminals start in your home folder, so in the right terminal run:

macOS and Linux:

```bash
cd ~/demos/python-feequote
source .venv/bin/activate
copilot
```

Windows:

```powershell
cd ~/demos/python-feequote
.\.venv\Scripts\Activate.ps1
copilot
```

Then type `/model` and pick the higher-tier model, and leave that session at its prompt.

### Step 1: VS Code, start a subagent survey and leave it running

**Do:** open Copilot Chat, start a new chat with **+**, pick **Agent** in the agent picker.

**Paste:**

```
Use a subagent for this so the file contents stay out of this chat. Survey every module that reads the domestic fee policy and report where a per-channel policy would have to be threaded through. Do not edit anything; produce a findings list with file and line references.
```

**Do:** do not wait for it. Move on to Step 2; you come back in Step 6.

**Ask** the attendees, who answer in chat: "Will the release-notes skill fire from a plain
request, without naming it? Type yes or no."

### Step 2: VS Code, the reviewer agent

**Do:** start another new chat with **+**. In the agent picker choose **reviewer**.

**Paste:**

```
Review the uncommitted change to the domestic cap in feequote/core/pricing.py and the tests that cover it
```

**Expected:** a review of the cap change in `feequote/core/pricing.py` and the updated tests,
in this order: correctness risks, convention violations, missing tests, readability. It ends
with a one-line verdict (approve, approve with nits, or request changes). It does not edit any
file.

**Point at:** the verdict line, and that no files changed.

**Do:** straight away, in the left terminal (the plain terminal, not the Copilot session),
start the same agent from the command line so its review runs while you continue:

```bash
copilot --agent reviewer -p "Review the uncommitted change to the domestic cap in feequote/core/pricing.py and the tests that cover it"
```

You come back to its output in Step 5.

### Step 3: VS Code, the release-notes skill

**Do:** start another new chat with **+** and pick **Agent** (not reviewer; the reviewer is
read-only and cannot run the script).

**Paste:**

```
Write release notes for v0.1.0 to v0.2.0
```

**Expected:** the agent runs `python scripts/release_notes.py v0.1.0 v0.2.0` and turns the
output into this shape:

```
## FeeQuote v0.2.0

### Features
- Add reviewer custom agent
- Add release-notes skill

### Chores
- Add repository instructions and AGENTS.md
- Add MCP server configuration
```

A `### Fixes` heading with "none" may also appear; there are no fix commits in that range.

**Point at:** the script run in the tool calls, and the headings matching the house format in
`.github/skills/release-notes/SKILL.md`.

### Step 4: VS Code, open the agent file

**Do:** open `.github/agents/reviewer.agent.md` for ten seconds.

**Point at:**

- `tools:` lists `read` and `search` (names every surface understands) plus older
  per-surface names. Each surface ignores the names it does not recognize, and none of them
  can edit files.
- `model:` is a single model name that both surfaces read.

### Step 5: Copilot CLI, the same agent and an MCP server

**Do:** switch to the left terminal where you started the reviewer in Step 2. Wait
for it to finish if it is still working; its output is what you show next.

**Expected:** the same kind of review as Step 2, printed in the terminal, from the same file.
The prompt names the file on purpose: the reviewer's tools are read-only and include no shell,
so in the terminal it cannot run `git diff` to discover what changed by itself.

**Say:** "Same file, an agent picker entry in the editor and a flag in the terminal."

**Do:** switch to the right terminal, where the interactive Copilot CLI session is waiting, and
paste:

```
/mcp show
```

**Expected:** the MCP servers the CLI has loaded, including the built-in
`github-mcp-server`. The repository's `.vscode/mcp.json` is read only by VS Code, not by the
CLI.

**Paste:**

```
Using the GitHub MCP server, list the five most recent open pull requests on github/awesome-copilot and summarize each in one line.
```

**Expected:** five pull requests, one line each (the content changes daily). This repository
has no GitHub remote, which is why the query targets a public repository. Give it sixty
seconds; if the segment is already running long, skip this query (see below).

**Leave this CLI session open** for segment 4.10.

### Step 6: VS Code, back to the subagent survey

**Do:** switch back to the first chat from Step 1.

**Expected findings:**

- `feequote/core/pricing.py`: `DOMESTIC_POLICY` defined (around line 34) and used by
  `compute_fee` (around line 70).
- `feequote/services/transfer_service.py`: `TransferService.quote` calls `compute_fee`
  (around line 48), and `Transfer.channel` is available there.
- `feequote/__main__.py`: reaches it through `TransferService().quote`.
- `tests/test_pricing.py`: asserts the policy values.
- `feequote/jobs/reconciliation.py` does not read it; it uses the legacy helper.

**Point at:**

1. The subagent entry in the chat. It is collapsed; expand it to show its own tool calls, the
   prompt it was given and the result it returned.
2. Hover the subagent entry to see the credits it used.
3. If the Agents window is open, the parent session there also shows the subagent's model and
   elapsed time.

**Say:** "Delegation is probable, not guaranteed. Anything that has to happen every single
time belongs in a test, a linter or an instruction file."

**Say:** "Ten parallel sessions working from a bad instruction file produce ten times the
rework. That is the argument for putting the effort into the file."

### If something goes wrong

- The survey did not use a subagent: show the same numbers for the main session and say
  delegation is the agent's decision, which is why it is probabilistic.
- The skill does not fire from the plain request: that answers the prediction question.
  Then paste `Use the release-notes skill to write release notes for v0.1.0 to v0.2.0.`
- Short on time: skip the MCP query and keep `/mcp show`. Then also skip Steps 1 and 2 of
  segment 4.10 and its prediction, because there is no query timeline to expand.
- Only if you have pushed this repository to GitHub yourself: `Using the GitHub MCP server,
  list the open pull requests on this repository and summarize each in one line.`

### Where this shows up in real repositories

- A chore someone repeats every sprint (release notes, a changelog, a dependency report)
  that turns into a skill with a script, so it is done the same way every time.
- Wide read-only sweeps ("find every caller", "list every config flag") that would flood a
  main conversation, handed to a subagent or a read-only agent.

---

## Segment 4.10: power-user tips

- **Where:** the Copilot CLI session in the right terminal from segment 4.9, VS Code, then
  the left terminal.
- **Branch:** `main` (unchanged from 4.9).
- **What this shows:** collapsing tool calls changes only what you see; what lowers the bill is
  making fewer of them, and a command you already know costs nothing when you run it yourself.
  Headless mode runs one prompt with tight permissions.

**Ask** the attendees, who answer in chat: "How many tool calls do you think the MCP query
took? Guess a number before we expand the timeline."

### Step 1: Copilot CLI, expand the timeline

**Do:** in the right terminal's CLI session, make sure the prompt box is **empty** (the
shortcuts below do something else while you are typing; press Esc to clear it). Then press,
one at a time:

- **Ctrl+O**: expands the most recent items in the timeline, here the MCP query's tool calls.
- **Ctrl+T**: shows or hides the model's reasoning.

**Expected:** the MCP query's tool calls, collapsed to one line each by default, open up to
show their details. Count them aloud against the guesses in chat.

**Point at:** the collapsed view is the default, and the details are still there when you need
them. (Ctrl+E expands every item in the session. On a timeline this short it shows the same as
Ctrl+O, so it is not part of the demo; mention it for long sessions.)

### Step 2: VS Code, collapsed tool calls in chat (only if on time)

**Do:** switch to the subagent survey chat from segment 4.9 and click one collapsed tool call
group open.

**Say:** "Collapsing is a display setting. These tool calls already ran and their results were
already sent to the model, so collapsing them doesn't change the bill. What changes the bill is
making fewer calls."

### Step 3: terminal, the same question two ways

**Do:** type `/exit` in the right terminal. In the left terminal (the plain terminal in the
repository folder), answer the question yourself first:

```bash
git grep -n compute_fee -- feequote tests
```

**Expected:** the matching lines print instantly: the definition, the call in the service, the
tests, and any test message that names it. No model was involved, so this cost nothing. Inside
a Copilot CLI session the `!` prefix does the same: `!git grep -n compute_fee`.

**Do:** now ask an agent the same question, headless, with one permission rule. Paste this
command. It is the same on all three systems:

```bash
copilot -p "Using git grep, list every caller of compute_fee" --allow-tool "shell(git:*)"
```

**Expected:** one collapsed tool call (`git grep`), then the answer, listing:

- `feequote/services/transfer_service.py`
- `tests/test_pricing.py`
- the definition in `feequote/core/pricing.py`

It may also mention `tests/test_architecture.py` or the instruction files, which contain the
name in text or messages; none of those are callers. After the answer comes a summary with an
`AI Credits` line and a `Tokens` line. In a rehearsal on the Python repository the run took
about 8 seconds, one tool call, about 55k input tokens and 7.75 AI credits; your numbers depend
on the model.

**Point at:** the `AI Credits` and `Tokens` lines, against nothing at all for the `git grep`
you ran yourself. Then: one prompt, one permission rule, and nothing else allowed.

**Say:** "Same answer. One cost nothing, the other cost [read the credits]. When you already
know the command, run it yourself with `!` and give the agent the result. When an agent does
run in a pipeline, start from deny by default, allow only what the task needs, and never give
it production credentials. In a script, add `-s` so only the answer is printed."

### If something goes wrong

- The answer lists files under `.venv` or cache folders: the agent searched with something
  other than `git grep`. Run the command again; `git grep` only searches tracked files.
- The output says a tool was denied: `-p` runs without prompts, so nothing can be approved
  mid-run. The agent usually searches with its built-in tool, which counts as `read`. Run the
  command again with `--allow-tool "read"` added.
- Ctrl+O shows nothing new: the prompt box is not empty, or the items are already expanded.
  Press Esc and try again, or move on; the timeline is not the point of the segment.
- Short on time: skip Steps 1 and 2 and run only Step 3.

### Where this shows up in real repositories

- Agents added to CI jobs with every tool allowed "to make it work", and later found running
  commands nobody intended.

---

## Rehearsal checklist

- [ ] The venv is activated in the terminal Copilot runs from, and a bare
      `python -m pytest -q` prints `57 passed` there.
- [ ] `python -m pytest -q`, `ruff check .` and `mypy feequote tests` all pass on `main` and
      on `demo-start`.
- [ ] On `demo-checks`, `python -m pytest -q` prints `57 passed`, while `ruff check .` reports
      F401 and `mypy feequote tests` reports one arg-type error.
- [ ] `git log --oneline --decorate --all` shows five commits on `main`, tags `v0.1.0`,
      `v0.2.0` and `demo-checks-base`, the `demo-start` branch, and one extra commit on
      `demo-checks`.
- [ ] The repository folder contains no `DEMO_SCRIPT.md`, `prompts.txt` or `RUN_COMPARISON.md`;
      they are open from `~/demos/demo-kit/python-feequote` on a monitor that is not shared,
      outside the demo VS Code window.
- [ ] In VS Code, the agent's terminal uses the `.venv` interpreter: run B's `python -m pytest -q`
      and the release-notes skill's `python scripts/release_notes.py` both run.
- [ ] No personal instruction files are active in the CLI or your VS Code profile.
- [ ] Ctrl+O and Ctrl+T work in a Copilot CLI session in your terminal app (prompt box empty).
- [ ] Whether `/model` keeps its choice between sessions: ______ (the script sets it each time
      either way).
- [ ] `python -m feequote quote --amount 123500 --from AU --to AU` prints fee 1112.
- [ ] Segment 4.3: both worktrees exist, both CLI sessions are started, trusted, and set to
      their models. Lower-tier model: ______ Higher-tier model: ______
- [ ] `~/demos/demo-kit/python-feequote/tier-check/test_tier_check.py` is on disk, and on an untouched `demo-start` worktree the
      segment 4.3 check fails its first two tests and passes the third.
- [ ] Copilot CLI is signed in, `/mcp show` lists `github-mcp-server`, and the MCP query
      against `github/awesome-copilot` returns pull requests.
- [ ] You know how to put two terminals side by side in your terminal app. Windows only:
      PowerShell 7 (`pwsh --version`) is installed and is the Windows Terminal default profile.
- [ ] The headless command in segment 4.10 runs as written. Note whether it needed
      `--allow-tool "read"`, which search tool it used: ______, and its AI credits: ______
- [ ] Standard mode label shown by Shift+Tab: ______
- [ ] The `reviewer` agent appears in the VS Code agent picker on `main`.
- [ ] `copilot --agent reviewer -p "Review the uncommitted change to the domestic cap in feequote/core/pricing.py and the tests that cover it"` runs with the cap change in
      place and names it in the review, and the agent refuses when asked to edit a file, on
      both surfaces. `model` in
      `.github/agents/reviewer.agent.md` names a model this account can use.
- [ ] `python scripts/release_notes.py v0.1.0 v0.2.0` prints four commits.
- [ ] Run A and run B were rehearsed from a clean `demo-start`, and, if you are keeping one,
      the rehearsal tally in `RUN_COMPARISON.md` is filled in.
- [ ] The subagent survey was rehearsed in VS Code: you know how to expand the subagent entry,
      where its credits appear on hover, and where the Agents window shows its model and time.
- [ ] Segment 4.2: you know whether the context window control shows a token count before the
      first send, and whether the `Sources:` rule survived `/compact` in rehearsal.
- [ ] Collapsed tool calls in VS Code chat on this build look like: ______
- [ ] Each segment timed in rehearsal: 4.2 ___ 4.3 ___ 4.5 ___ 4.7 ___ 4.9 ___ 4.10 ___
- [ ] `prompts.txt` matches this script (it was generated from it).
