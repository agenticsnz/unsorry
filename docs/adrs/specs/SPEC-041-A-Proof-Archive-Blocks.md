# SPEC-041-A: Proof Archive Blocks

Implements: [ADR-041](../ADR-041-Proof-Archive-Blocks.md) · Status: Living · Updated: 2026-06-15

## 1. Terms

- **Active package**: the package that receives normal proof PRs and contains the current working set.
- **Archive block**: an immutable Lake package containing a frozen batch of proved goals.
- **Block target size**: 40 proved goals for the initial rollout. This is an operational threshold, not a soundness invariant.
- **Archive pin**: the exact Git/Lake revision by which the active package depends on an archive block.

## 2. Archive Cut Rule

The active package becomes archive-eligible when it contains at least 40 proved goals that are not already assigned to an archive block.

The cut tool should:

1. Count proved goals from `goals/*.aisp` records with `status≜proved`.
2. Exclude any goal already recorded in an archive manifest.
3. Select the oldest stable proved goals until the next block reaches 40, unless doing so would split a tightly coupled decomposition tree.
4. Emit a proposed manifest before moving files.

The report-only command is:

```bash
python3 -m tools.archive --size 40
python3 -m tools.archive --size 40 --json
```

It emits the next archive block id, eligible proved count, selected goal/module
pairs, and dependency/decomposition groups deferred to avoid splitting related
work.

Maintainers may defer a cut for dependency-tree coherence, but should record the reason in the archive manifest or PR body.

## 3. Package Shape

The first implementation keeps archive packages in the same repository:

```text
packages/
  unsorry-active/
  unsorry-archive-0001/
  unsorry-archive-0002/
```

Each archive block contains:

- the archived proof modules;
- corresponding `library/index/*.aisp` records;
- enough goal/proof-run metadata to preserve provenance and leaderboard attribution;
- an archive manifest.

The manifest records:

- block id, for example `unsorry-archive-0001`;
- proof count;
- goal ids;
- module names;
- source commit used to cut the archive;
- validation commit;
- Lean/mathlib/archive dependency pins.

## 4. Validation Rules

When an archive block is frozen, CI validates **provenance + packaging**, not soundness from scratch
(ADR-048 verify-on-ingest — the proofs were kernel-verified when active and are byte-identical now):

- byte-identity / immutability: the archived `.lean` is byte-for-byte the already-verified active
  proof (ADR-018 archive-aware immutability, enforced in `gate-a-prepare`);
- `lake build --wfail` (packaging sanity — the archive package is a new Lake project);
- statement-binding regeneration/checks for archived goals;
- forbidden elaboration option checks;
- Gate B validation over archived index/proof-run metadata.

It does **not** re-run `leanchecker` kernel replay or the axiom audit on archived proofs — re-running
them on the same immutable artifact re-proves nothing and OOM-killed memory-bound runners (#764).

After freezing:

- normal active proof PRs validate the active package and the archive pins they depend on;
- archive source is not re-audited or replayed on every active PR;
- any PR changing archive source, archive manifests, archive pins, archive packaging tools, `lean-toolchain`, Lake files, or Gate A tooling is trust-bearing and must full-validate the affected boundary;
- scheduled or manual full validation over all archive blocks remains the backstop for toolchain/mathlib migrations.

## 5. Gate A Integration

Gate A should distinguish three validation scopes:

1. **Active PR scope**: changed active modules plus existing incremental replay/audit closure.
2. **Archive boundary scope**: archive pin or manifest changes; validate the active package against the pinned archive and full-validate the touched archive block.
3. **Global scope**: toolchain, Lake, Gate A, or archive packaging changes; full-validate active plus affected archive blocks.

The default must always fail toward a larger validation scope when the changed-path classifier cannot decide.

**Runs in the `gate-a-archive` job** (`needs: [detect]`, `if: archive == 'true'`). Under ADR-048
(verify-on-ingest) this job no longer kernel-replays archived proofs — it does packaging sanity
(`lake build --wfail`) + provenance, which fits the standard runner. (Earlier cuts — #823's chunking,
#838's 16 GB pin — tried to make the re-replay fit; ADR-048 removes the re-replay instead, which is
both cheaper and a better match for what an archive is.)

## 6. Rollout Plan

1. Add a report-only tool that prints:
   - proved goals not assigned to an archive;
   - proposed next archive block at target size 40;
   - dependency/decomposition groups that should not be split.
2. Cut `unsorry-archive-0001` from the oldest stable proved goals.
3. Update imports and package configuration so active proofs can import archive modules through the pinned package dependency.
4. Update Gate A to use the three validation scopes in §5.
5. Compare CI timings before and after the first cut, then decide whether the block target should remain 40 or move to 50/100.

## 7. Acceptance Criteria

- A docs-only ADR/spec PR passes protocol and does not trigger Lean validation.
- `python3 -m tools.archive --size 40` can identify the next 40-goal block without moving files.
- A frozen archive block can be validated independently from the active package.
- A normal proof PR after the first archive cut does not enumerate archived proof modules in the active replay/audit set.
- A PR changing an archive pin or archive source triggers full validation for the affected archive boundary.

## 8. Cutting a block — runbook

A block moves a set of proved goals from the active package into a new frozen archive package; the
active `goals/<id>.aisp` records stay (re-pointed to the archive), only the proved artefacts move.

Two non-obvious invariants — both learned the hard way (blocks 0003/0004) — govern a correct cut:

> **(A) Archive whole decomposition trees, never split one.** A decomposition record and its
> `parent` + all `subs` are *atomic* to Gate B: the package is validated as its own tree, so a
> sub-lemma's `src≜decompositions/<D>` must resolve there (GB008) and the decomposition's `parent`
> must be a known goal there (GB016) — and any active sub still referencing a moved decomposition
> fails GB008 on the active side. So a tree goes to the package **entirely or not at all**.
>
> **(B) Never touch generated docs in the cut.** `docs/leaderboard.*`, `docs/metrics/*.json`,
> `docs/targets.md`, and `docs/proof-graph.*` / `docs/proofs-contributors-visualisation.*` are
> regenerated and committed by **push-to-`main`** workflows (no PR gate checks them). If the cut
> regenerates them, it races main's refresh bot and conflicts forever. Leave them at the
> **merge-base** version (zero delta); main refreshes them after merge.

**1. Plan.** On an up-to-date checkout of `main`:

```bash
python3 -m tools.archive --size 40 --json   # next block id + candidate goals (module, sha, proof-runs, index)
```

Confirm `block_id` is the next after existing `packages/unsorry-archive-*` (a stale checkout
mis-numbers — verify).

**1b. Restrict to whole trees (invariant A).** Build the decomposition graph from active
`decompositions/*.aisp` (each record's `parent≜…` + `id≜…` subs are one component). Keep a candidate
goal only if it is standalone (in no decomposition) **or** its entire component is also in the
candidate set; drop split-tree goals (they archive later when their whole tree is eligible together).
The block is then whole-trees + standalone goals — which is usually **fewer than 40**; that is
correct and preferable to a broken 40. (The report-only planner is not yet tree-aware; this is the
gap the write-mode tool should close.)

**2. Create `packages/unsorry-archive-NNNN/`** (mirror 0002's layout):

- `lakefile.toml` (`name = "unsorryArchiveNNNN"`, one `[[lean_lib]]` `UnsorryArchiveNNNN`,
  `srcDir = "library"`, `globs = ["Unsorry.+"]`, `mathlib` pinned to the **current** root `rev`),
  `lean-toolchain` (copy root), `lake-manifest.json`, and `archive-manifest.json`
  (`block_id`, `target_size`, `proof_count`, `status: "frozen"`, `source_commit`,
  `validation_commit: null`, `pins`, `notes`, `goals: [{goal, module}, …]`).
- For each archived goal `<id>` (module `Unsorry.<Mod>`): **move** `library/Unsorry/<Mod>.lean`,
  its `library/index/<sha>.aisp`, `goals/<id>.lean` (**byte-identical** — required for the ADR-018
  archive-aware exemption), `backlog/<id>.md`, and its `proof-runs/*`; **copy** `goals/<id>.aisp`
  (provenance).
- **Decompositions:** move a `decompositions/<parent>.*.aisp` into the package **only when its whole
  tree is archived** (invariant A). Then re-point the package's sub-lemma records' `src` to
  `packages/unsorry-archive-NNNN/decompositions/…`.

**3. Retire from active.** Remove the moved artefacts from the active tree, and edit each active
`goals/<id>.aisp` to the archived end-state (keep the record, re-point it; `sha` unchanged):

```
⟦Ω:Goal⟧{ … status≜archived … }
⟦Σ:Source⟧{ src≜packages/unsorry-archive-NNNN/backlog/<id>.md }
⟦Λ:Artifact⟧{ lean≜packages/unsorry-archive-NNNN/goals/<id>.lean ; sha≜<unchanged> ; aff≜… }
```

**4. Leave generated docs alone (invariant B).** Do **not** run the board generators. If any got
touched, restore them to the merge-base: `git checkout "$(git merge-base origin/main HEAD)" --
docs/leaderboard.* docs/metrics/*.json docs/targets.md docs/proof-graph.* docs/proofs-contributors-visualisation.*`.
The PR must show **zero** generated-doc changes; main auto-refreshes them post-merge.

**5. Validate locally** before the PR:

```bash
python3 -m tools.gate_b validate .                                            # active records
python3 -m tools.gate_b validate packages/unsorry-archive-NNNN --goals-root packages/unsorry-archive-NNNN  # the package as its own tree (catches A)
python3 -m tools.gate_a.check_goal_immutability --base <PR base>              # goal-.lean removals (ADR-018)
git diff --name-only <PR base> -- docs/ | grep -v docs/adrs/ || echo "no generated-doc delta — good"  # invariant B
```

**6. Open the PR** titled `chore(archive): retire active copies for block NNNN`. Gate A
full-validates the new archive package (ADR-041 §4) and replays the **shrunk** active library; the
goal-`.lean` removals pass the ADR-018 immutability gate (byte-identical archived copy in the
manifest).

## 9. Operating at scale

With a high inflow of proofs (many contributors / many agents), the active set crosses the block
target continuously, so archiving is **not** a one-off: the active package's full-replay and audit
cost (the Gate A long pole, especially on memory-bound runners where replay can't parallelise) grows
between cuts. Two implications:

- **Cut early and often.** Treat 40 as a ceiling, not a goal; a smaller effective active set keeps
  full validation fast. Cut a new block whenever the planner reports a full block of eligible goals.
- **Automate the cut.** The §8 runbook is mechanical — it should become a `tools.archive` *write*
  mode (perform the moves, write the manifest, re-point the active records) plus a scheduled/threshold
  trigger that opens the retire PR automatically once a whole-tree block is eligible. The write mode
  **must** encode both invariants from §8: **(A)** select only whole decomposition trees + standalone
  goals (make the planner tree-aware), and **(B)** never write generated docs (leave them to the
  push-to-`main` refresh workflows). Both are what made the hand-cuts conflict / fail validation; a
  tool that bakes them in is the durable fix for a high proof-inflow repo.

  **Write mode (implemented).** `python3 -m tools.archive.apply --source-commit <sha> --toolchain
  <tc> --mathlib <rev>` performs one cut with both invariants baked in: tree-aware selection over the
  active decomposition graph (A) and zero `docs/` writes (B). It moves the proof module,
  `library/index/<sha>.aisp`, `goals/<id>.lean`, `backlog/<id>.md`, `proof-runs/<id>.*`; copies
  `goals/<id>.aisp` into the package; re-points each active `goals/<id>.aisp` to the archived
  end-state (`status≜archived`; `src`/`lean` prefixed with the package path; `sha` unchanged); moves
  whole-tree decomposition records; and writes the package `lakefile.toml` / `lean-toolchain` /
  `lake-manifest.json` / `archive-manifest.json`. Seed/translate goals with `lean≜∅` (e.g.
  `Unsorry.Basic`) are skipped — they are not archivable proof modules. The tool deliberately does
  **not** run git or open the PR: validate per §8 step 5, then open the retire PR by hand. The
  scheduled/threshold auto-trigger is implemented by `tools/archive/auto_cut.sh` +
  the `auto-archive` workflow (hourly + `workflow_dispatch`): when active
  proved-not-archived ≥ a ceiling (default 20) and no archive PR is open, it cuts
  one block, validates (Gate B active + package, ADR-018 immutability, zero-docs),
  and opens an auto-merge retire PR. Bounding the active set this way keeps Gate A
  full-replay / `lake build --wfail` under memory — the durable fix for the
  exit-137 OOM on a high proof-inflow repo.

## 10. Why the active set must stay small — build performance

Archiving is not only about memory; it is the primary lever on **Gate A wall-clock**.
Every Gate A job (`gate-a-prepare`, `gate-a-audit`, `gate-a-replay`) runs
`lake build UnsorryLibrary --wfail` over the **whole active library**, and its time
scales with the active module count. Measured on the trusted runner with a warm
cache: an active library of **457 modules** took **~233 s** for the `--wfail`
library build alone (≈100 modules recompiled, the rest cache-replayed) — repeated
in each Gate A stage. Draining the active set to a few dozen modules cuts that to
seconds. Archived proofs are *not* rebuilt or replayed (ADR-048: provenance +
packaging only), so they leave the build entirely.

**Bulk sweep.** When the active set has grown large (e.g. a backlog accumulated
faster than the hourly auto-archive could cut it), drain it in one pass instead of
waiting ~one block per cron tick:

```bash
SRC=$(git rev-parse origin/main); TC=$(tr -d '[:space:]' < lean-toolchain)
ML=$(python3 -c 'import json,glob;m=sorted(glob.glob("packages/unsorry-archive-*/archive-manifest.json"));print(json.load(open(m[-1]))["pins"]["mathlib"])')
git checkout -B feat/bulk-archive-sweep origin/main
while python3 -m tools.archive.apply --source-commit "$SRC" --toolchain "$TC" --mathlib "$ML" 2>&1 | grep -qv "no eligible"; do :; done
# then validate per §8 step 5 and open ONE retire PR
```

This loops `tools.archive.apply` (oldest-first, whole-trees only, §8 invariant A)
until no eligible whole-tree goal remains, producing one block per cut. Validate
exactly as a single cut (Gate B on the active tree **and** each new package as its
own tree; `check_goal_immutability`; zero generated-doc delta) and open one retire
PR. The newest proofs that are not part of a complete archivable tree stay active;
auto-archive (§9, ceiling 20) then maintains the small active set.
