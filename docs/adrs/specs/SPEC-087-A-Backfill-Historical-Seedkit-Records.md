# SPEC-087-A: Backfill Historical seedkit Records

Implements: [ADR-087](../ADR-087-Backfill-Historical-Seedkit-Records.md) · Status: Living · Updated: 2026-06-23

ADR-087 retroactively brings already-merged seedkit records into line with the
honest provenance and difficulty ADR-086 made standard going forward. This spec
is the contract for the backfill tool, its identification logic, scope,
idempotency, automation, and tests. It is two corrections (provenance, difficulty)
delivered as one idempotent, self-healing pass that extends the existing
attribution sweep.

## 1. Deliverables

| # | Deliverable | Surface | CODEOWNERS? |
|---|---|---|---|
| D1 | Provenance rules extended to the induction-ring + `seedkit`-provider cases | `tools/repo/relabel_attribution.py` | no (auto-merge) |
| D2 | Goal-difficulty corrector for seedkit-origin goals | `tools/repo/relabel_attribution.py` (sibling fn) | no |
| D3 | Tests for D1 + D2 (rules, idempotency, collision guard) | `tools/repo/tests/test_relabel_attribution.py` | no |
| D4 | Both corrections run from the existing scheduled sweep | reuse `attribution-relabel.yml` as-is | **only if** its commit scope must change |

## 2. Provenance backfill (D1)

Extend `_RULES` and relax `relabel_record` in `tools/repo/relabel_attribution.py`.

**Rule table** — keep the engine-disambiguating `(agent, model-shape) →
(provider, model)` shape; add the induction-ring mappings and the `seedkit`-agent
rows:

| agent | model shape matched | honest provider | honest model |
|---|---|---|---|
| `mac-158f` | `template-*` | `python` | `sympy` | *(unchanged)* |
| `claude-web` | `template-zmod-decide` | `lean` | `decide` | *(unchanged)* |
| `claude-web` | `template-induction-ring` | `lean` | `ring` | **new** |
| `seedkit` | `template-zmod-decide` | `lean` | `decide` | **new** |
| `seedkit` | `template-induction-ring` | `lean` | `ring` | **new** |

**Guard** — currently `relabel_record` returns early unless `provider≜claude` is
present, which skips every `provider≜seedkit` record. Relax it to process a record
whose provider is **not already honest** — i.e. `provider≜claude` *or*
`provider≜seedkit` — and rewrite that provider token (whichever it is) to the
rule's honest provider, then `model_re.sub` the model. A record already on
`provider≜lean`/`python` matches no provider-swap and is returned unchanged
(idempotent). `mac-158f` stays `python/sympy` — its `template-*` is genuinely
sympy, not Lean; agent-keying preserves this.

**Scope & invariants (unchanged from today):** `_iter_files` already globs active
`library/index/*.aisp` **and** `packages/unsorry-archive-*/library/index/*.aisp`;
`solver≜` is never touched; rewriting is metadata-only (soundness-neutral).
Expected first-run effect: ~158 records (the `template-induction-ring` family +
the `provider≜seedkit` `template-zmod-decide` records the sweep previously
skipped) → `lean/ring`|`lean/decide` (exact count reported by the tool).

## 3. Difficulty backfill (D2)

A pure `correct_difficulty(text) -> (text, changed)` plus a goal-record pass in
`main`, fed by an `index_is_seedkit(text)` / `goal_of(text)` collection pass.

**Identify a seedkit-origin goal — by provenance, not by name.** seedkit's goal-id
prefixes are irregular (`gzmod-`, `alt-geometric-ratio-`, `factorial-dvd-consec-`,
`odd-square-sum-coeff-`, the residue family ids, …) and easy to under-enumerate,
so identification is driven by the authoritative signal: the goal's own **proof
index record**. A first read-only pass over the index records (active + archive)
collects every `goal≜<id>` whose record carries a seedkit signature
(`index_is_seedkit`) — one of the kit's agents (`agent≜seedkit`/`claude-web`) with
either a `template-*` model or, post-relabel, the Lean engine (`provider≜lean;
model≜decide`/`ring`), tolerant of pre- and post-provenance-relabel state. The
difficulty pass then edits **exactly those** goals' records; a goal whose proof is
not a seedkit signature is never touched. (No goal-id prefix list to maintain.)

**Edit.** For an identified goal whose record has `difficulty≜<2-5>`, rewrite to
`difficulty≜1`. Idempotent: `difficulty≜1` (or `0`) is left unchanged. The
statement, `sha`, `status`, and every other field are untouched — only the single
`difficulty≜` digit changes (ADR-018 governs the statement, not difficulty).

**Scope.** `goals/*.aisp` only. Goals are never archived under `packages/`
(`tools/leaderboard/generate.py`), so one pass over `goals/` corrects the
`difficulty_points` of both active and archived proofs. Expected first-run effect:
~561 seedkit goal records → `difficulty≜1` (gzmod ~403, faulhaber ~158; exact
count reported). ~306 `gzmod-` goals proved by the separate `mac-158f` pipeline
are **not** matched — identification is by proof provenance, not goal-id family.

## 4. Automation (D4)

Fold both corrections into the tool's `--apply` path so a single
`python3 -m tools.repo.relabel_attribution --apply .` performs provenance + goal
difficulty in one run. Reuse the existing `attribution-relabel.yml` (post-merge +
hourly, commits via `REFRESH_TOKEN` with `[skip ci]`, report-only if unset).

**CODEOWNERS check:** confirm the workflow stages all modified tracked files
(e.g. `git add -A` / `git commit -am`). If it already does, `goals/` changes ride
along with **no workflow edit** — keeping the whole change a single
`tools/repo/`-only auto-merge PR. Only if the workflow stages an explicit
`library/index` pathspec must it be widened to include `goals/`, which is a
`.github/` CODEOWNERS edit needing a code-owner-approved PR; prefer the no-edit
path.

## 5. Tests (D3)

Extend `tools/repo/tests/test_relabel_attribution.py` (pure functions, no I/O):

- each new provenance rule rewrites its record (`claude`/`seedkit` +
  induction-ring → `lean/ring`; `seedkit` + zmod-decide → `lean/decide`);
- `mac-158f template-*` still → `python/sympy` (not Lean); a genuine LLM proof
  (`agent≜claude-web; model≜sonnet`) is untouched; an already-`lean` record is a
  no-op (idempotency);
- `index_is_seedkit`: a kit agent + template-* or relabelled `lean/decide`|`ring`
  is a fixture; a genuine LLM proof by the same agent (`model≜opus`) and another
  contributor's `lean/decide` are **not**;
- difficulty corrector: `difficulty≜4` → `1`; `difficulty≜1` unchanged
  (idempotent);
- end-to-end: a seedkit goal's record is corrected to `1` while a non-seedkit
  goal at the same difficulty is left untouched; a second run is a no-op.

## 6. Rollout & impact

1. Land the tool PR (auto-merge, `tools/repo/` only).
2. The next scheduled/post-merge sweep settles the corpus in one pass
   (~561 goals + ~158 index records), then converges to a no-op.
3. The leaderboard regenerates: fixture contributors' `difficulty_points` and
   score **drop** to reflect honest difficulty 1 (chat-bit-01 most). **This is an
   announced, maintainer-approved standings change** (ADR-087) — note it in the
   release/changelog so the board movement is not mistaken for a bug.
4. `solver≜` credit and credited-proof counts are unchanged.

## 7. Out of scope

- Changing `solver≜` credit, credited-proof counts, or removing fixtures from the
  board (ADR-087 is ranking-neutral on the credit axis).
- Any statement edit (ADR-018) — difficulty is the only goal-record field touched.
- Going-forward generation — already handled by ADR-086 / SPEC-086-A.
