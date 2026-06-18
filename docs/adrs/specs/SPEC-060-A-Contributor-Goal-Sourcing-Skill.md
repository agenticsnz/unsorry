# SPEC-060-A: Contributor-Facing Goal-Sourcing Skill

Implements: [ADR-060](../ADR-060-Contributor-Goal-Sourcing-Skill.md) · Status: Living · Updated: 2026-06-16

Three deliverables, each its own PR: (1) `Skills/unsorry-goal-sourcing/` (the
skill), (2) `tools/sourcing/gen_triples.py` (the triple assembler), (3) a
`--sourcing` mode for the leaderboard. The schemas live in SPEC-003-A and the
pipeline in SPEC-043-A; this spec is the contract that binds them into a
contributor-runnable workflow.

## 1. The sourcing pipeline the skill walks (one source of truth)

The skill drives the four-gate pipeline of SPEC-043-A §1; it does **not** restate
the gate internals, it invokes the tools and interprets exit codes.

| Gate | Command | Pass | Fail |
|---|---|---|---|
| 1 Absence | `python3 -m tools.sourcing.check_absence --pattern '<rx>' [--loogle '<q>'] --json` | exit `0` (`no-local-match`); record `mathlib_rev` | exit `1` (`possible-duplicate`) → drop or re-scope |
| 2 Type-check | `lake build UnsorryGoals` | builds | does not elaborate → fix statement |
| 3 Non-triviality | `python3 -m tools.sourcing.check_triviality goals/<slug>.lean --json` | exit `0` (`non-trivial` \| `allowlisted` \| `override`) | exit `1` (`trivial`) → drop; exit `2` (`probe-error`) → **fix tooling, never admit** |
| 4 Provable + skeptic | `lake env lean <scratch>` (intended proof compiles) + adversarial skeptic re-running gates 1–2 | compiles & skeptic finds no disguised mathlib lemma | drop |

Battery (gate 3, fixed, from `check_triviality.py`): `rfl, trivial, decide,
norm_num, omega, simp, simp_all, aesop, ring, linarith, tauto`. `native_decide`
and `nlinarith/positivity/field_simp/gcongr` are **deliberately excluded** —
multivariate SOS/field/`gcongr` goals therefore survive by design and are a
sanctioned **hard-target** family (ADR-035).

## 2. Difficulty bar (skill-enforced; gate-unenforced)

The `difficulty` field (0–5, SPEC-003-A) is self-tagged and not checked by any
gate. The skill enforces ADR-060's maximum-difficulty mandate:

- Target **difficulty ≥ 3**; a sourced goal SHOULD carry **≥ 1 decomposition
  edge** in its backlog decomposition-sketch (a goal a contributor can see how to
  split is a goal with depth).
- Prefer hard families, sourced **in parallel** (ADR-031, ADR-043): Freek-#50
  **Phase-2 Euler substrate** (planar-graph Euler characteristic, tree edge
  counts, cycle-space rank, f-vector relations — provable now) **and** Phase-3
  library growth (olympiad / PutnamBench / miniF2F / multivariate SOS &
  field inequalities). The skill MUST NOT generate substrate-blocked geometric
  statements that cannot type-check at the pinned mathlib (gate 2 would fail).
- The bar is advisory at CI; the skill states it, and review applies it.

## 3. `tools/sourcing/gen_triples.py` (the triple assembler)

A pure, tested tool that turns one validated candidate into the three on-disk
files and Gate-B-validates them. No network; no git.

### CLI

```
python3 -m tools.sourcing.gen_triples --slug <kebab-id> \
    --lean-sig '<lean signature after the theorem name>' \
    --statement '<one-line English statement>' \
    --difficulty <0-5> \
    --source '<source line>' --reference '<reference line>' \
    --absence '<gate-1 verdict + rev + date>' \
    --triviality '<gate-2 verdict + battery + rev + date>' \
    --decomposition '<intended-proof sketch>' \
    [--aff -20] [--date YYYY-MM-DD] [--root .] [--validate] [--force]

python3 -m tools.sourcing.gen_triples --from-candidate '<candidate line>' --difficulty 3 ... [flags]
```

- Writes exactly three files (SPEC-003-A schema for a **fresh** goal):
  - `goals/<slug>.lean` — `import Mathlib\n\ntheorem <snake(slug)> <sig> := by\n  sorry\n`
  - `goals/<slug>.aisp` — header `𝔸5.1.goal.<slug>@<date>`, `γ≔unsorry.goal`,
    `⟦Ω:Goal⟧{id≜<slug>;phase≜prove;status≜open;difficulty≜<d>}`,
    `⟦Σ:Source⟧{src≜backlog/<slug>.md}`, `⟦Γ:Deps⟧{deps≜⟨⟩}`,
    `⟦Λ:Artifact⟧{lean≜goals/<slug>.lean;sha≜∅;aff≜<aff>}`, `⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩`.
  - `backlog/<slug>.md` — `# <slug>`, the statement, then the six bullets
    **Source / Reference / Absence / Triviality / Difficulty / Decomposition
    sketch**.
- `snake(slug)` = slug with `-`→`_`; `<slug>` MUST match `[a-z0-9][a-z0-9-]*` and
  contain no dots.
- `--validate` (default on in CI use) runs `python3 -m tools.gate_b validate .`
  over the written tree and fails non-zero on any GB finding.
- `--force` allows overwriting; default refuses to clobber an existing
  `goals/<slug>.*` (ADR-018 immutability — a changed statement gets a new slug).
- Exit `0` on a valid triple; `1` on validation failure; `2` on usage error.

### Tests (TDD, `tools/sourcing/tests/test_gen_triples.py`)

- A generated triple passes `tools.gate_b.validator` (round-trip).
- `.aisp` header/`id`/filename agree; `status≜open` ⇒ `sha≜∅`; difficulty in
  range; the band line is exactly `⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩`.
- `.lean` is the canonical `import Mathlib` + `theorem … := by` + `  sorry` shape.
- slug validation rejects dots/uppercase/leading hyphen; `--force` guard refuses
  to clobber.
- `snake()` maps kebab→snake correctly.

## 4. `Skills/unsorry-goal-sourcing/` (authored via skill-creator)

Convention matches the four existing unsorry skills (frontmatter `name` +
trigger `description`; body < ~150 lines; `references/`, `assets/`, `agents/`).

- **SKILL.md** — Purpose; Scope boundary (already-proven, mathlib-absent, never
  open conjectures); the four-gate walkthrough with exact commands; the
  difficulty bar; two-tier model (cheap `backlog/candidates/<theme>.md` staging
  vs full-triple promotion via `gen_triples.py`); conflict rules (§5); PR &
  announce discipline; a closing handoff pointer to `unsorry-proof-authoring`.
- **references/** — `sourcing-pipeline.md` (gate detail + exit codes incl
  `probe-error`=2 and the allowlist/override admit paths), `triple-format.md`
  (the SPEC-003-A fresh-goal schema verbatim, `status≜open`/`sha≜∅`),
  `themes-and-difficulty.md` (the hard families + the substrate ceiling),
  `fork-contributor-path.md` (Gate-B-on-`ubuntu-latest`, fork PR + Approve-and-run,
  no-pre-claim + merge-time dedup, `gh auth`/`UNSORRY_SOLVER` for credit).
- **assets/** — `goal-triple.lean.tmpl`, `goal-record.aisp.tmpl`,
  `backlog-entry.md.tmpl`, `candidate-line.tmpl`, PR-body + #81/#400 announcement
  templates.
- **agents/** — an adversarial-skeptic sub-agent prompt (re-runs gates 1–2 as an
  independent reviewer + greps known lemma families: `fib_dvd`, `centralBinom`,
  Vandermonde `add_choose_eq`, `stirlingSecond`, `add_pow`, `(x±y)∣(xⁿ±yⁿ)`).

## 5. Conflict model (no pre-claim + merge-time dedup, Tier 0)

There is **no atomic pre-claim** for sourcing (the claims branch / ADR-004 is
prove-only and fork-inaccessible; ADR-053/054 are Proposed). The skill MUST:

1. Assign **one `backlog/candidates/<theme>.md` per session** as the namespace
   guard (concurrent edits to the same theme file conflict in git, so two workers
   take different theme files).
2. `git fetch origin` and **dedup generated slugs AND statements** against the
   live `origin/main` `goals/` set immediately before every batch (a race
   *window*, not a race-free primitive).
3. Treat **merge-time dedup as the backstop** — a raced duplicate is caught by the
   absence/triviality gates (full-Mathlib `simp`/`aesop` catches renamed dups) or
   rejected at merge; the cost is wasted compute, never an unsound/duplicate
   *merged* goal (ADR-018).
4. Write triples via the **GitHub git API tree path** (createTree → commit → ref),
   not local git, when the swarm is concurrently churning the shared `.git`.
5. **Never** push to the claims branch or invoke `agent.sh` claim/push/merge from
   a fork.

The skill is written against a thin claim-interface seam (`acquire/release` no-ops
in Tier 0) so an ADR-053 backend can replace it without rewriting the skill.

## 6. Sourcing leaderboard (`tools/leaderboard --sourcing`)

Adds a mode that credits whoever **sourced** a goal, independent of proof credit.

- **Attribution source:** git add-author over `goals/*.aisp` (the earliest commit
  that added the file) — the same `git_add_authors()` mechanism the proof
  leaderboard already uses for historical attribution; reuse it, do not
  reimplement. No `.aisp` schema change (ADR-060). Apply the existing
  `docs/metrics/contributor-aliases.json` mapping.
- **CLI:** `python3 -m tools.leaderboard --sourcing [<root>]` prints the sourcing
  leaderboard markdown; `--write` additionally emits
  `docs/metrics/sourcing-leaderboard.json` (schema_version 1) alongside the
  existing artifacts; `--check` covers it for drift.
- **Per-sourcer fields:** `sourcer` (handle), `git_author`, `display_name`,
  `github`, `profile_url`, `avatar_url`, `sourced_goals`, `difficulty_points`
  (Σ difficulty over sourced goals), `proved` / `open` split (join on goal
  status), `earliest_sourced`, `latest_sourced`. Ranking: `sourced_goals` desc,
  then `difficulty_points` desc — mirroring the proof `_score()` shape.
- A contributor may appear on both the proof and sourcing leaderboards; the two
  are computed independently.
- **Tests** (`tools/leaderboard/tests/`): a fixture tree with goals added by two
  authors yields the expected per-sourcer counts and difficulty points; alias
  mapping is applied; `--check` round-trips.

## 7. Protocol constraints (non-negotiable)

- `chore(sourcing):` PR title; ≤ 50 goals per PR (cycle-4: 100 overran the 45-min
  `gate-a-prepare`; gate does not enforce the cap, the skill does).
- Do **not** regenerate `docs/targets.md` in a sourcing PR (ADR-036 — it refreshes
  post-merge via `targets-board.yml`).
- mathlib pinned to release tags, never built from source; `lake exe cache get`
  for deps (ADR-002).
- Changelog fragment (ADR-040) for the skill-introduction and `gen_triples.py`
  PRs; a routine sourcing *batch* of goals needs none.
- Announce each merged wave on #81 and update the #400 program-status comment
  (SPEC-043-A §5); flip `backlog/candidates` checkboxes `[ ]`→`[x]`.
