# SPEC-093-A: lean4export + nanoda Independent-Checker Pilot

Implements: [ADR-093](../ADR-093-Lean4export-Nanoda-Independent-Checker-Pilot.md) · Status: Living · Updated: 2026-06-24

An **observe-only** pilot answering SPEC-049-A §6 Phase-3 open questions **Q2**
(cross-machine `lean4export` determinism) and **Q3** (`nanoda` wall-clock /
timeout-bound, no >100× pathology). It **gates nothing**, admits no content, and
leaves the authoritative gate (`leanchecker`) unchanged. Deliverable: a **data
report**. Modeled on the non-required `gate-a-shard-pilot.yml`.

## 1. Tooling (pinned)

- **`lean4export`** at the tag matching `lean-toolchain` — currently **`v4.30.0`**
  (exact match to the project pin, confirmed 2026-06-24). Re-verify the tag tracks
  `lean-toolchain` whenever the toolchain bumps (protocol §10).
- **`nanoda`** (`ammkrn/nanoda_lib`) built from a pinned commit. Its compatibility
  with the current export format is **part of what the pilot measures** — if it
  cannot parse a `v4.30.0` export, that is a recorded Q3 result (a blocker), not a
  failure to force.

## 2. The driver (`tools/pilot/export_checker_pilot.py`)

For each module in a sample (input-selected or the N most-recently-changed library
modules), the driver:

1. runs `lean4export <module>` → captures the export **bytes** + **sha256**;
2. (Q2) compares the sha256 against the same module's export produced on a *second*
   run / runner — `determinism: stable` iff all runs' hashes match;
3. (Q3) runs `nanoda` against the export under a hard **timeout `T`** → records
   wall-clock, exit status, `timed_out`;
4. times `leanchecker` on the same module → the `nanoda`/`leanchecker` **ratio**.

Emits `pilot-report.json` (per-module rows) **and** `pilot-report.md` (summary:
determinism verdict; export-size p50/p95; `nanoda` wall-clock p50/p95/max; ratio
p50/p95/max with the **>100× pathology flag**; timeout-hit rate). Production-ready;
no stubs (protocol §8). The driver is **pure orchestration** — it admits nothing and
is never on a soundness path.

## 3. Workflow (`.github/workflows/export-checker-pilot.yml`, NON-REQUIRED, manual)

`workflow_dispatch` only; `permissions: contents: read`; gates nothing. Inputs:
`modules` (sample size or explicit list), `runs` (cross-run determinism, default 2),
`timeout` (per-module `nanoda` cap). Jobs: build the library (Namespace `.lake`
warm) → install pinned `lean4export` + `nanoda` → run the driver → **upload**
`pilot-report.json` + `pilot-report.md` as artifacts. The report is the deliverable
(also pasted onto #5684 to feed a future Phase-3 ADR).

## 4. Metrics → the two questions

| Question | Metric | Decision it informs |
|---|---|---|
| **Q2 determinism** | cross-run/-machine sha256 stability rate | export-hash equality is a valid cross-machine oracle (→ proceed to Q3) **or** export is tamper-evidence/dedup only (→ Phase-3-as-decentralisation is dead; stay Track A) |
| **Q3 wall-clock** | `nanoda`/`leanchecker` ratio + timeout-hit rate | adopt export re-check as a 2nd kernel-diverse anchor (no >100× pathology) **or** keep `leanchecker` authoritative, export advisory only |

## 5. Tests (unit, hermetic — `tools/pilot/tests/`)

The driver's pure logic is unit-tested **without** the real tools, on **recorded
fixture stdout** (real `lean4export` / `nanoda` output samples — not mocks of the
system under test, protocol §8): metrics aggregation (size capture, cross-run hash
comparison → `stable|divergent`, ratio computation, the `>100×` pathology flag,
timeout-hit tally), the `pilot-report.json` schema, and report rendering.

## 6. Conformance

- **Non-gating:** a regression test asserts the workflow is `workflow_dispatch`-only
  and admits no content (no path writes to `library/` / `UnsorryLibrary`); it never
  appears in any required-check `needs:`.
- **Determinism math:** the cross-run hash comparator is a pure, deterministic
  function of the recorded exports (unit-tested).
- **Blocker-as-result:** if `nanoda` cannot parse the export, the report records it
  as a Q3 outcome (status `incompatible`), and the pilot still exits 0 (observe-only).

## 7. Out of scope (each its own decision)

- A Phase-3 rebuild / making the export re-check merge-gating.
- Lowering the central re-check below `p = 1` — a separate ADR amending ADR-049,
  gated on this pilot's data.
- TEE / hardware attestation (rejected, ADR-049).
- The Track-A per-shard rebuild de-dup (#5751) — a different (capacity) lever.
