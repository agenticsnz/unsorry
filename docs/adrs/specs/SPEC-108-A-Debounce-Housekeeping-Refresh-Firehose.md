# SPEC-108-A: post-merge refresh debounce guard

Implements: [ADR-108](../ADR-108-Debounce-Housekeeping-Refresh-Firehose.md) · builds on
ADR-082 (single-pass refresh) / ADR-098 (freshness gate) · Status: Draft · Updated: 2026-06-29

Contract for the min-interval debounce that takes the five post-merge housekeeping refreshers off
the per-merge path while keeping `push` primary. Pure/seam-isolated logic in
`tools/repo/refresh_debounce.py` (unit-tested without git for the decision, with a temp git repo
for the lookup); each workflow is a thin caller.

## 1. Helper API — `tools/repo/refresh_debounce.py`

- `should_skip(last_refresh_epoch: int | None, now_epoch: int, window_s: int) -> bool` — pure.
  Returns `True` iff `last_refresh_epoch is not None and 0 <= now_epoch - last_refresh_epoch < window_s`.
  - `last_refresh_epoch is None` (never refreshed) ⇒ `False` (fail-open: refresh).
  - `window_s <= 0` ⇒ `False` (guard disabled).
  - `now_epoch - last_refresh_epoch >= window_s` ⇒ `False` (window elapsed).
  - A future `last_refresh_epoch` (clock skew, `now - last < 0`) ⇒ `False` (never skip on skew).
- `last_refresh_epoch(root: Path, subject: str) -> int | None` — committer epoch (`%ct`) of the
  most recent commit on `HEAD` whose **subject line** contains `subject` (fixed-string match,
  `git log -1 -F --grep=<subject> --format=%ct`). `None` if no match or git is unavailable
  (fail-open). Runs against the checked-out tree (`fetch-depth: 0`, so full history is present).
- `main(argv) -> int` — CLI:
  `--subject <str>` (required), `--window-seconds <int>` (required, `>= 0`),
  `--now <epoch>` (optional, injectable for tests; default = current UTC epoch),
  `--root <path>` (optional, default `cwd`). Prints exactly one line `skip=true` or `skip=false`
  to stdout (GitHub `$GITHUB_OUTPUT` form). Exit `0` on success, `2` on usage error. Any internal
  error ⇒ print `skip=false` and exit `0` (**fail-open**: a broken guard must never block a
  refresh, only ever decline to skip).

## 2. Decision semantics (must hold)

- **Fail-open everywhere.** Missing history, unparseable time, disabled window, clock skew, or any
  exception all resolve to `skip=false`. The guard can suppress a redundant refresh but must never
  cause a board to go un-refreshed because the guard itself failed.
- **Bounded staleness.** A board's source-relative lag never exceeds `window_s` during sustained
  activity (the first merge past the window refreshes). This keeps `window_s` < the
  `tools/leaderboard/freshness.py` threshold (30 min) sufficient to never trip the freshness gate
  (ADR-108 §"Why this is safe").

## 3. Workflow wiring (all five refreshers)

Each of `leaderboard.yml`, `proofs-visualisation.yml`, `targets-board.yml`, `adr-index.yml`,
`attribution-relabel.yml`:

1. After `setup-python`, before the refresh step, add:
   ```yaml
   - name: Debounce — skip a push refresh that already landed recently (ADR-108)
     id: debounce
     if: github.event_name == 'push'
     run: |
       python3 -m tools.repo.refresh_debounce \
         --subject "<the workflow's refresh-commit subject>" \
         --window-seconds "${{ vars.UNSORRY_REFRESH_DEBOUNCE_SECONDS || '600' }}" \
         >> "$GITHUB_OUTPUT"
   ```
   On non-`push` events the step is skipped, so `steps.debounce.outputs.skip` is empty and the
   refresh runs (schedule/dispatch are never debounced).
2. Gate the existing refresh step:
   `if: steps.tok.outputs.present == 'true' && steps.debounce.outputs.skip != 'true'`.
   The report-only (no-token) and freshness-gate steps are unchanged.

Per-workflow `--subject` (must equal the literal commit subject each pushes):
| Workflow | subject |
|---|---|
| `leaderboard.yml` | `docs: refresh leaderboard` |
| `proofs-visualisation.yml` | `docs: refresh proofs-contributors-visualisation` |
| `targets-board.yml` | `docs: refresh targets board` |
| `adr-index.yml` | `docs: refresh ADR index` |
| `attribution-relabel.yml` | `chore: relabel template proofs` |

3. The three without a schedule (`proofs-visualisation`, `targets-board`, `adr-index`) add a
   backstop `schedule: - cron: "*/15 * * * *"` (flushes the final pre-quiet batch; GitHub throttles
   it to ~1×/hr — it is a safety net, not the primary path). `leaderboard.yml` (`*/15`) and
   `attribution-relabel.yml` (`47 * * * *`) keep their existing schedules.

## 4. Tests — `tools/repo/tests/test_refresh_debounce.py`

- `should_skip`: None→False; recent (`now-last < window`)→True; exactly at window→False;
  past window→False; `window=0`→False; future `last` (skew)→False.
- `last_refresh_epoch`: temp git repo with an interleaved history → returns the **most recent**
  matching commit's `%ct`; returns `None` for an unmatched subject and for a non-git dir.
- `main`: with `--now` injected against a temp repo → prints `skip=true` inside the window and
  `skip=false` outside / when disabled; usage error (`2`) on missing/negative args; fail-open
  (`skip=false`, exit `0`) when `--root` is not a git repo.

## 5. Out of scope / invariants preserved

- No change to what any refresher generates (`--write-if-stale` / `--write` / `--apply` unchanged),
  to the `REFRESH_TOKEN` push auth (#417), the `concurrency` coalescing, or the `[skip ci]`
  no-re-trigger property. The freshness gate (ADR-098) and its 30-min threshold are unchanged.
