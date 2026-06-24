# SPEC-091-A: Sharded Gate A Axiom Audit

Implements: [ADR-091](../ADR-091-Sharded-Gate-A-Axiom-Audit.md) · Status: Living · Updated: 2026-06-24

Shard the Gate A axiom audit across N parallel runners to cut the now-dominant
audit cost (~55–65% of per-PR verifier minutes; #5656/#5682) without weakening the
every-module-audited invariant (ADR-048/049). It mirrors SPEC-063-A for the audit
lane (SPEC-063-A §6 named it the fast-follow). Deliverables: the
`plan-audit`/`audit-shard`/`combine-audit` tooling, a non-required pilot leg, and —
after the pilot is green — the required-gate promotion (§5).

## 1. The driver (`tools/gate_a/parallel_modules.py`)

The shard logic **reuses the existing audit scope machinery verbatim**; it adds
four small surfaces and changes none of `scoped_audit_targets` / `replay_scope` /
`split_evenly` / the serial `audit` semantics.

- **`compute_audit_targets(root, base) -> AuditScope`** — the single source of
  truth for *what to audit*, factored out of `audit`:
  - `mode "full"` — `base is None`, or the diff is untrusted / global-impact
    (`forces_full_audit`); fail-closed: an unscopeable base yields the FULL
    `AuditScope(all_library, all_goals)`, never empty;
  - `mode "incremental"` — changed library closure (ADR-033) + changed goals;
  - `mode "none"` — `base` given, no library or goal module changed (empty).
  `plan_audit_shards`, `audit_shard`, and the serial `audit` all read it, so **a
  shard can never audit a different set than a full audit would**.
- **`plan_audit_shards(root, shards, base) -> {shards, count, mode}`** — emits the
  matrix index list `[0 … effective-1]` where `effective = min(shards, count)` and
  `count = len(scope.library) + len(scope.goals)`. `count == 0` ⇒ `shards == []`
  (empty matrix ⇒ matrix job skipped). CLI: `parallel_modules plan-audit --shards N
  [--base B]` prints the JSON object.
- **`audit_shard(root, shard_index, shard_total, output, base) -> int`** —
  recomputes the scope from source (same SHA ⇒ identical set), forms the ordered
  target list `scope.library ++ scope.goals`, partitions with
  `split_evenly(targets, shard_total)`, and audits slice `shard_index` only:
  builds `axiom_audit`, then runs `lake exe axiom_audit <lib members>` and `lake
  exe axiom_audit --allow-sorry <goal members>` (each only if its membership is
  non-empty), serially (one mathlib-resident process at a time), and writes the
  slice's combined JSON array to `output`. Out-of-range index ⇒ empty `[]` fragment,
  exit 0. CLI: `parallel_modules audit-shard --shard-index i --shard-total N
  --output shard-i.json [--base B]`.
- **`combine_audit_reports(fragments, output) -> int`** — reads the per-shard JSON
  array fragments, concatenates and `sort`s by `decl` (matching the serial
  `audit`'s combined report), writes the unified `axiom-report.json` for the sticky
  footprint comment. CLI: `parallel_modules combine-audit --output axiom-report.json
  shard-0.json shard-1.json …`.

**No module list crosses a job boundary** — each leg re-derives its slice from the
shared git SHA, so the auditor's inputs stay locally-derived (the ADR-049 invariant
is preserved trivially). The audit JSON fragments cross only as *outputs* (evidence
for the footprint comment), never as trusted inputs to a verdict.

## 2. The soundness invariant (must hold for every audit shard plan)

`split_evenly` produces **disjoint, covering** contiguous partitions of the
deterministically-ordered target list `scope.library ++ scope.goals` (each itself a
`sorted`/stable list). Therefore, for a fixed SHA:

1. **Coverage:** `⋃ over i of split_evenly(targets, N)[i] == scope.library ∪
   scope.goals` — no module skipped.
2. **Exactly-once:** the slices are pairwise disjoint — no module audited twice
   (and, with the cover assert, no gap hidden by overlap). `collectAxioms` is a pure
   per-declaration function, so partitioning never changes a verdict.
3. **Trusted inputs:** every shard rebuilds oleans on trusted CI and feeds
   `axiom_audit` only local module names (no `download-artifact` into the gate).
4. **Same pinned toolchain:** all shards check out the same SHA and restore the
   same cache (ADR-002).
5. **Fail-closed:** an unscopeable base ⇒ the FULL set; a non-green shard ⇒ red.

Across all shards green, (1)+(2) give: **every in-scope module axiom-audited
exactly once** — the same guarantee the serial `--jobs 1` audit gives.

## 3. Tests (unit, hermetic — `tools/gate_a/tests/test_parallel_modules.py`)

- **`test_audit_shards_partition_covers_every_module_exactly_once`** — the
  invariant: run every shard, assert the audited slices (library ∪ goals) are
  pairwise disjoint and their union is the full audit scope.
- **`test_audit_shards_partition_covers_incremental_scope_exactly_once`** — same on
  the incremental path (changed library closure + changed goals, nothing outside).
- **`test_plan_audit_shards_*`** — full plan; cap at module count (no empty
  shards); empty matrix on no change (`mode none`); **fail-closed to full** on git
  failure and on a global-impact change (`forces_full_audit`).
- **`test_audit_shard_*`** — runs only its slice; library vs `--allow-sorry` goal
  split is correct; out-of-range writes an empty fragment; failure propagation;
  fail-closed-to-full on git failure; **emits a composable JSON fragment**
  (`combine_audit_reports` over all shard fragments == the serial audit's report).
- **Conformance (`test_decentralised_runner_conformance.py`)** — `audit_shard`
  feeds `axiom_audit` only locally-derived module names; no client artifact is a
  trusted input (ADR-049).

The existing audit/replay tests still pass — the `audit` refactor (extracting
`compute_audit_targets`) is behaviour-preserving.

## 4. Pilot leg (`gate-a-shard-pilot.yml`, NON-REQUIRED, manual)

Add an audit mode to the existing pilot (`workflow_dispatch`; input `mode: replay |
audit`, default `replay`; `shards` default 8; optional `base`). The audit path runs
three jobs paralleling the replay pilot:

1. **`plan`** (ubuntu) — `parallel_modules plan-audit --shards N` (reads source +
   git only, no build); outputs `matrix` and `count`.
2. **`audit`** (`namespace-profile-unsorry-1`, `if: count != '0'`,
   `strategy.matrix.shard: fromJSON(plan.matrix)`, `fail-fast: false`) — each leg
   restores the `.lake` cache, builds the library + statement bindings, and runs
   `audit-shard --shard-index <i> --shard-total N --output shard-<i>.json`,
   uploading the fragment artifact.
3. **`cover`** (`if: always()`) — passes when `count == 0`, else fails closed unless
   `needs.audit.result == 'success'`; downloads the fragments and runs
   `combine-audit` as a smoke check of the merge.

It gates nothing; it is the ADR-058-required real-runner validation before
promotion.

## 5. Promotion (required `gate-a.yml`, after the pilot is green)

The required `gate-a.yml` audit job is promoted to the same three-job shape as
replay (SPEC-063-A §5):

- **`gate_a_audit_plan`** (`ubuntu-latest`, `needs: [detect, gate_a_prepare]`) —
  runs `plan-audit --shards ${{ vars.UNSORRY_AUDIT_SHARDS || 8 }} [--base
  BASE_SHA]` (the same incremental BASE_SHA logic the serial audit used) and
  outputs `matrix` + `count`.
- **`gate_a_audit`** (`needs: […, gate_a_audit_plan]`, `if: … && count != '0'`,
  `strategy.fail-fast: false`, `matrix.shard: fromJSON(plan.matrix)`) — each leg
  keeps the existing audit setup (Namespace volume / GitHub-cache restore of
  gate-a-prepare's oleans, the `--wfail` build, statement bindings) and runs
  `audit-shard --shard-index ${{ matrix.shard }} --shard-total N --output
  axiom-report-shard-${{ matrix.shard }}.json [--base BASE_SHA]`, uploading the
  per-shard fragment.
- **`gate_a_audit_cover`** (`if: always() && active`) — a **pure coverage assert**:
  fails closed unless the plan succeeded **and** (`count == 0`, audit skipped →
  vacuous) **or** the audit matrix is `success`. This is the single audit signal.

> **Normative — no artifact into the required gate.** Unlike the pilot's cover
> (§4), `gate_a_audit_cover` **must not** pull the per-shard fragments back in: the
> SPEC-049-A §2 invariant forbids any artifact reaching the central gate, and the
> conformance suite enforces it by asserting `gate-a.yml` contains no
> artifact-download step (a blunt string guard — even the *phrase* must not
> appear). The per-shard footprint fragments are therefore uploaded as **diagnostics
> only** (downloadable from the Actions UI), and the combined per-PR footprint
> *comment* is **dropped from the required gate** — it lives in the non-required
> shard pilot, which may legitimately combine the fragments. The authoritative audit
> is unaffected: each shard's `axiom_audit` fails closed on any whitelist violation,
> turning the shard (and the cover) red. `combine_audit_reports` remains the tested
> merge used by the pilot and available for local/backstop use.

The aggregator `gate-a` adds the three jobs to `needs:` and reads
`gate_a_audit_cover.result` for the audit outcome (replacing the direct
`gate_a_audit.result`); the required context name `gate-a` is **unchanged**
(ADR-058: do not rename required contexts). `N` is the operator capacity knob
`vars.UNSORRY_AUDIT_SHARDS` (default 8), separate from `UNSORRY_REPLAY_SHARDS`. The
daily full-audit backstop is retained.

## 6. Out of scope (fast-follow)

- Intra-runner `--jobs > 1` on a fat audit-shard profile (the serial-per-shard path
  bounds peak memory like replay; a fat profile could parallelise within a shard).
- Sharding the daily full backstop.
- Operator runner-pool scaling (ADR-058) — orthogonal capacity, not a repo change.
