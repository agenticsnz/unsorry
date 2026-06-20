# SPEC-066-A: Queued-Proofs Board

Implements: [ADR-066](../ADR-066-Queued-Proofs-Board.md) | Status: Accepted | Updated: 2026-06-17

The queued-proofs board is a generated docs page, `docs/queue.html` (plus a
machine-readable `docs/queue.json`), that shows the proofs submitted to the
`queued/prove/*` queue (ADR-058) but not yet merged, grouped by **solver**, in the
shared site UX (ADR-038). It is produced by `tools.queue_board` and refreshed on a
schedule by `.github/workflows/queue-board.yml`.

## 1. CLI

```
python3 -m tools.queue_board [<repo-root>]            # JSON to stdout (default)
python3 -m tools.queue_board --json [<repo-root>]     # board model as JSON
python3 -m tools.queue_board --html [<repo-root>]     # standalone HTML to stdout
python3 -m tools.queue_board --write [<repo-root>]    # write docs/queue.{html,json}
python3 -m tools.queue_board --check [<repo-root>]    # CI drift check (exit 1 if stale)
```

- `--json`, `--html`, `--write`, `--check` are mutually exclusive; more than one
  is a usage error (exit 2), matching `tools.visualiser`.
- An optional `--open-prs <file>` flag names a file containing open prove-PR head
  ref names (one per line, e.g. `queued/prove/<goal>/<agent>-<hex>`) used to label
  submissions `in-flight` vs `waiting`. When omitted, PR status is unknown: every
  submission is `waiting` and `pr_status_known` is `false`.
- The default (no mode) writes the JSON model to stdout.

## 2. Data sources (all best-effort; a failed read degrades, never crashes)

1. **Queue refs** — `git -C <root> for-each-ref --format='%(refname) %(objectname:short) %(committerdate:short)' refs/heads/queued/prove/ refs/remotes/origin/queued/prove/`.
   Outside a git checkout this yields no submissions (parity with ADR-032's
   `git_provenance` degrade-to-empty).
2. **Solver / model** — the `⟦Π:Provenance⟧{solver≜…; model≜…}` of the index
   entry the branch adds, read from `git -C <root> diff <main>...<ref> -- library/index/`
   (the added `+` lines), parsed with the same field grammar as `tools.gate_b.records`.
   Falls back to the branch commit's git author resolved through
   `docs/metrics/contributor-aliases.json` (`tools.leaderboard.generate._alias_for`).
3. **Proved-on-main exclusion** — the set of goals already proved on `main`, from
   `tools.leaderboard.generate.proofs(root)` (the `library/index` markers). A
   queued branch whose goal is already proved is omitted (ADR-064 dedup parity).
4. **Open-PR head refs** — optional, supplied by the workflow via `--open-prs`.

## 3. Parsing rules (pure, unit-tested without git)

- `parse_ref(refname)` → `(goal, branch_suffix)` from
  `…/queued/prove/<goal>/<branch_suffix>`; the goal is the single path segment
  after `queued/prove/`, the branch suffix is the final segment. Refs that do not
  match this shape are ignored.
- `branch_shortname(refname)` → the `queued/prove/<goal>/<suffix>` portion, used to
  match against open-PR head refs and to dedupe a goal's local+remote duplicates of
  the same branch.
- `solver_from_index_diff(diff_text)` → `(solver, model)` from the added
  `solver≜`/`model≜` fields, or `(None, None)` if absent.
- A submission is uniquely keyed by its `branch_shortname` (so the same branch seen
  as both a local and an `origin/` ref counts once).

## 4. Board model (`docs/queue.json`)

```json
{
  "schema_version": 1,
  "source": "queued/prove/* refs + library/index provenance",
  "pr_status_known": true,
  "summary": {
    "queued_submissions": 0,
    "waiting": 0,
    "in_flight": 0,
    "distinct_goals": 0,
    "solvers": 0
  },
  "solvers": [
    {
      "solver": "ruvnet",
      "github": "ruvnet",
      "profile_url": "https://github.com/ruvnet",
      "submissions": 0,
      "waiting": 0,
      "in_flight": 0,
      "distinct_goals": 0,
      "queued": [
        {"goal": "…", "branch": "queued/prove/…/…", "sha": "…",
         "model": "…", "date": "YYYY-MM-DD", "state": "waiting"}
      ]
    }
  ]
}
```

- Solvers are ranked by `submissions` desc, then `distinct_goals` desc, then
  display name. A submission with no resolvable solver is grouped under a stable
  `unknown` bucket (never dropped). Within a solver, submissions are sorted by goal
  then branch for determinism.
- `state ∈ {"waiting", "in-flight"}`. When `pr_status_known` is `false` every
  submission is `waiting`.
- JSON is emitted with `indent=2`, `ensure_ascii=False`, trailing newline.

## 5. HTML rendering (`docs/queue.html`)

- Self-contained page sharing the ADR-038 design language: Tailwind CDN + Inter,
  centred white card, the shared top-nav (`tools.site_nav`) with **Queue** current,
  a header wordmark + summary chips (`N queued · W waiting · F in-flight · G goals`).
- One section per solver (GitHub-linked where a handle resolves), each listing its
  queued submissions in a table: goal (linked to the goal's Lean file), branch,
  model, submitted date, and a `waiting`/`in-flight` badge.
- A note states the page lists proofs submitted to the queue but not yet merged,
  that freshness is bounded by the scheduled refresh, and — when `pr_status_known`
  is `false` — that PR status was unavailable so all are shown as waiting.
- Contains no unreplaced `__PLACEHOLDER__` tokens.

## 6. Refresh workflow (`.github/workflows/queue-board.yml`)

- Triggers: `schedule` (cron `*/15 * * * *`, matching the dispatcher/reaper cadence)
  and `workflow_dispatch`. **Not** push-to-`main` (the queue is not a function of
  `main`).
- Steps: checkout with full history; fetch `queued/prove/*` refs; gather open prove
  PR head refs via `gh pr list --search 'head:queued/prove/' --json headRefName`
  into a file passed as `--open-prs`; run `python3 -m tools.queue_board --write .`;
  commit `docs/queue.html docs/queue.json` to `main` with `[skip ci]` using the
  `REFRESH_TOKEN` admin identity and the 5-attempt retry-rebase from
  `proofs-visualisation.yml`. When `REFRESH_TOKEN` is unset, degrade to a
  report-only warning (no push), as the other refresh workflows do (#417).

## 7. Test coverage (TDD, `tools/queue_board/tests/test_generate.py`)

- Pure parsers: `parse_ref`, `branch_shortname`, `solver_from_index_diff`.
- `build_board` over constructed submissions: grouping by solver, ranking, distinct
  goals, `unknown` bucket, proved-goal exclusion, waiting/in-flight labelling, and
  `pr_status_known=false` path.
- Render: `render_json` shape; `render_html` carries the shared nav (Queue current),
  summary chips, per-solver sections, badges, and no unreplaced placeholders.
- A git-integration test builds a real repo with `queued/prove/*` branches (one a
  `reroute-*` branch whose index `solver≜` differs from the committer) and asserts
  `--write` produces both files, `--check` is then clean, and a new queued branch
  reddens `--check`; attribution credits the index `solver≜`, not the branch agent.

## 8. Acceptance criteria

1. The CLI behaves as in §1; modes are mutually exclusive.
2. `--write` produces `docs/queue.{html,json}`; `--check` exits 0 when fresh and 1
   when stale.
3. Submissions are grouped by solver resolved from index provenance with alias
   fallback; `reroute-*` branches credit the index `solver≜`.
4. Goals already proved on `main` are excluded.
5. Submissions are labelled `waiting`/`in-flight` from the open-PR head refs; with
   no head-ref input, `pr_status_known` is `false` and all are `waiting`.
6. The HTML shares the site nav (with **Queue**) and design language and has no
   unreplaced placeholders.
7. The scheduled workflow refreshes `docs/queue.*` on `main`, degrading to
   report-only without `REFRESH_TOKEN`.
8. `python3 -m pytest tools/queue_board -q` and Gate B pass.
