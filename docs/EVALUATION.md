# Evaluation With GameDevBench

GameDevBench is the closest public benchmark for measuring whether Godot AI
actually helps agents complete Godot game-development tasks. It is not a unit
test for the plugin. It is a benchmark for agent success: pass@1, cost, tokens,
timeouts, and failure modes.

Use this document as the runbook before spending model budget.

## Why This Matters

GameDevBench's Godot-tooling track found that Godot-specific MCP tools did not
automatically improve task success. In the published DeepSeek v4-pro +
OpenHands runs:

| Stack | Tooling | pass@1 | Avg tokens/task | Avg cost/task |
| --- | --- | ---: | ---: | ---: |
| DeepSeek v4-pro + OpenHands | no Godot MCP | 29.1% | 1.19M | $0.052 |
| DeepSeek v4-pro + OpenHands | godot-ai live editor | 26.4% | 3.11M | $0.088 |
| DeepSeek v4-pro + OpenHands | prompt-only self-verification nudge | 36.9% | 2.28M | $0.093 |

The lesson is not "never use tools." The lesson is that every improvement must
be measured against a same-stack no-MCP baseline. Bigger tool catalogs can add
context cost without fixing the dominant failure mode: runnable-but-wrong game
logic.

## The Gate Rule

Always compare within the same stack:

```text
same model + same agent harness + same task list + same timeout
```

Do not use the published 29.1% DeepSeek + OpenHands number as the gate for a
different model or agent. For example, if evaluating GPT-5.5 + Codex, first run
the GPT-5.5 + Codex no-MCP baseline. Godot AI changes must beat that baseline,
not the DeepSeek + OpenHands baseline.

## Upstream Harness

Canonical repository:

```text
https://github.com/waynchi/gamedevbench
```

The upstream harness already includes:

- 333 zipped Godot tasks
- pass@1 validation
- token and cost accounting
- OpenHands, Codex, Claude Code, and Gemini CLI solvers
- a `godot-ai` MCP server option for OpenHands
- a prompt-only `--encourage-verification` option

Do not build a new benchmark harness before first trying to use upstream
GameDevBench. If we need changes, prefer upstreaming small patches there.

As of the local Phase 1 patch (`codex-godot-ai-mcp` in the GameDevBench fork),
Codex can also wire `--mcp-server godot-ai`. Keep that patch upstreamed before
treating Codex + Godot AI results as reproducible by other maintainers.

## Current Harness Caveats

These caveats are load-bearing:

- The upstream `godot-ai` path is currently pinned to a released package version
  in `gamedevbench/src/mcp_registry.py`:

  ```python
  GODOT_AI_VERSION = "2.7.5"
  ```

  That is useful for reproducing the published row, but it does not evaluate
  current `main` or an open PR.

- The version override must support local paths or git refs, not just semver.
  We need to benchmark unreleased branches before merging them. A useful
  upstream patch would allow inputs such as:

  ```text
  GODOT_AI_PACKAGE=git+https://github.com/hi-godot/godot-ai.git@main
  GODOT_AI_PACKAGE=file:///absolute/path/to/godot-ai
  ```

  and then build both the `uvx --from ...` server package and the editor addon
  checkout from the same source.

- In unpatched upstream GameDevBench, non-default MCP servers such as
  `godot-ai` are honored only by the OpenHands solver. The Phase 1 Codex patch
  adds per-task isolated `CODEX_HOME` config, preserves the screenshot MCP
  server, starts one `godot-ai` editor session per task, and supports parallel
  workers. Do not run Codex + `godot-ai` without that patch or an upstream
  equivalent.

- The released task zips do not expose the paper's four taxonomy buckets as a
  simple top-level category field. Until we get an upstream category map, use a
  fixed task-id smoke list rather than claiming category stratification.

- The cloned repository may not include per-run `results/*.json` files even
  though the README documents the published summary table. Treat the README
  numbers as target references, not as raw failure-analysis data.

## Setup

Clone and prepare GameDevBench outside this repository:

```bash
git clone https://github.com/waynchi/gamedevbench.git
cd gamedevbench
bash unzip_tasks.sh
uv run python validate_tasks.py
```

Use Python 3.12+ for OpenHands runs. Set `GODOT_EXEC_PATH` if `godot` is not on
`PATH`.

Create `.env` from `.env.example` and add only the keys needed for the stack
you are running.

On Windows, prefer an explicit executable path and UTF-8 process output:

```powershell
$env:GODOT_EXEC_PATH = "C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot.exe"
$env:PYTHONIOENCODING = "utf-8"
```

## Fixed Smoke Task List

Use a fixed smoke list for cheap iteration. This is a broad, deterministic sweep
across the task ids, not a taxonomy-stratified sample:

```yaml
tasks:
- task_0002
- task_0011
- task_0019
- task_0028
- task_0036
- task_0045
- task_0053
- task_0062
- task_0070
- task_0079
- task_0087
- task_0096
- task_0104
- task_0113
- task_0121
- task_0130
- task_0138
- task_0147
- task_0155
- task_0164
- task_0172
- task_0181
- task_0189
- task_0198
- task_0206
- task_0215
- task_0223
- task_0232
- task_0240
- task_0249
- task_0257
- task_0266
- task_0274
- task_0283
- task_0291
- task_0300
- task_0308
- task_0317
- task_0325
- task_0334
```

Save it in the GameDevBench checkout as `tasks_smoke_godot_ai.yaml`.

## Reproduction Runs

### Published DeepSeek + OpenHands Anchor

These runs validate that the harness behaves like the published setup. They are
optional if DeepSeek access is unavailable, but useful before trusting deltas.

No-MCP baseline:

```bash
uv run python gamedevbench/src/benchmark_runner.py \
  --agent openhands \
  --model deepseek-v4-pro \
  --run-name ds-openhands-baseline-smoke \
  run --task-list tasks_smoke_godot_ai.yaml
```

Published `godot-ai` shape:

```bash
uv run python gamedevbench/src/benchmark_runner.py \
  --agent openhands \
  --model deepseek-v4-pro \
  --enable-mcp \
  --mcp-server godot-ai \
  --run-name ds-openhands-godot-ai-smoke \
  run --task-list tasks_smoke_godot_ai.yaml
```

Self-verification nudge:

```bash
uv run python gamedevbench/src/benchmark_runner.py \
  --agent openhands \
  --model deepseek-v4-pro \
  --encourage-verification \
  --run-name ds-openhands-verify-smoke \
  run --task-list tasks_smoke_godot_ai.yaml
```

Expected published headline references for the full 333-task run:

- no-MCP: 29.1%
- `godot-ai`: 26.4%
- verification nudge: 36.9%

Smoke runs will not exactly match those percentages, but they should reveal
major setup mistakes before a full run.

### Current Godot AI

Before using this for merge decisions, patch GameDevBench so `godot-ai` can be
resolved from a local path or git ref. The benchmark must report the exact
source it used, for example:

```text
godot-ai source: git+https://github.com/hi-godot/godot-ai.git@<sha>
```

Then rerun the same matrix with a run name that includes the git SHA:

```bash
uv run python gamedevbench/src/benchmark_runner.py \
  --agent openhands \
  --model deepseek-v4-pro \
  --enable-mcp \
  --mcp-server godot-ai \
  --run-name ds-openhands-godot-ai-<sha>-smoke \
  run --task-list tasks_smoke_godot_ai.yaml
```

### Codex Stack

Codex comparisons must also be within-stack. A no-MCP Codex baseline is valid:

```bash
uv run python gamedevbench/src/benchmark_runner.py \
  --agent codex \
  --model gpt-5.5 \
  --run-name codex-gpt55-baseline-smoke \
  run --task-list tasks_smoke_godot_ai.yaml
```

Do not compare this number to DeepSeek + OpenHands.

With the Phase 1 Codex + `godot-ai` GameDevBench patch applied, run the shipped
`godot-ai` package reference:

```bash
uv run python gamedevbench/src/benchmark_runner.py \
  --agent codex \
  --model gpt-5.5 \
  --enable-mcp \
  --mcp-server godot-ai \
  --workers 2 \
  --run-name codex-gpt55-godot-ai-275-smoke \
  run --task-list tasks_smoke_godot_ai.yaml
```

That evaluates the released package pinned in GameDevBench, currently
`godot-ai==2.7.5`. It is useful as a shipped reference, but it is not the number
that decides whether current Godot AI changes help.

After the Phase 2 local/git-ref override lands, run the same command against
Godot AI `main` and then the verification-nudge variant. The gate is:

```text
Codex + godot-ai@main must beat Codex no-MCP on the same task list.
```

## Validated Codex Path

The Phase 1 Codex wiring was live-validated on Windows with Godot 4.7:

- A direct Codex probe called `godot-ai.editor_state` and received
  `current_scene = res://scenes/main.tscn` and
  `godot_version = 4.7-stable (official)`.
- A one-task run (`task_0002`) completed end-to-end and passed validation.
- A two-task parallel run (`task_0002`, `task_0003`, `--workers 2`) completed
  without hanging. Each worker used an independent sandbox, editor session,
  port pair, and temporary `CODEX_HOME`; `task_0002` passed and `task_0003`
  produced a normal validation failure. Both produced grades.

Observed GPT-5.5 + Codex + `godot-ai` cost on this smoke-sized sample:

| Run | Tasks | Result | Total tokens | Cost |
| --- | ---: | --- | ---: | ---: |
| one-task validation | 1 | 1 pass | 163,145 | $0.1032 |
| two-task parallel validation | 2 | 1 pass / 1 fail | 825,792 | $0.4171 |

Budget rough order from these observations:

- 40-task smoke across four configs: about $20-$30.
- Full 333-task headline run: about $150-$250.
- The verification-nudge config may cost more because agents spend extra time
  writing/running tests and can hit the 600s cap.

## Headline Runs

Run the full 333-task list only after the smoke tier is stable:

```bash
uv run python gamedevbench/src/benchmark_runner.py \
  --agent openhands \
  --model deepseek-v4-pro \
  --run-name ds-openhands-baseline-full \
  run --task-list tasks.yaml
```

Use distinct `--run-name` values for every configuration so `results/` stays
comparable.

## What To Record

Every scorecard should record:

- GameDevBench commit SHA
- Godot AI source: version, git ref, or local path
- Godot version
- agent harness and version
- model id
- task list
- timeout
- pass@1
- successes / failures / errors / skipped
- total and average input tokens
- total and average output tokens
- total and average cost
- total and average duration
- timeout count
- rate-limit count
- notes on hung tasks or manual recovery

Keep the raw `final_results.json` and `final_results.csv` from each run.

## Definition Of Done For Evaluation Infrastructure

- A smoke run can be launched with one copied command.
- The no-MCP baseline and `godot-ai` run use the same model, agent, task list,
  timeout, and harness commit.
- The `godot-ai` source is explicit and can point at unreleased branches.
- Raw results are archived.
- A summary scorecard is written before any feature claim is made.

## What This Unlocks

Once the scoreboard exists, proposed improvements can be judged by agent
success instead of intuition:

1. Verification features built on Godot AI's `test_run` and diagnostics loop.
2. Tool catalog trimming and resource-first reads to reduce context cost.
3. Visual feedback paths using editor/game screenshots and capture.

The merge bar for those changes is not "the feature works." The bar is "the
same-stack `godot-ai` run improves against the same-stack no-MCP baseline."
