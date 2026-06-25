# ADR-099: Per-Suite Mathlib Pin for Benchmark Suite Ingestion & Verification

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-099 |
| **Initiative** | Benchmark unsorry against known Lean suites (#5643, M8) |
| **Proposed By** | unsorry maintainers (directed by Chris Barlow, #6381) |
| **Date** | 2026-06-25 |
| **Status** | Proposed |

## Context

[ADR-092](ADR-092-Segregated-Benchmark-Track.md) established the segregated benchmark
track: each external Lean suite is imported as one [ADR-081](ADR-081-Problem-Admission-And-Intake-Pipeline.md)
skeleton package and scored as verified pass@k. The importer
(`tools/intake/import_benchmark.py`) re-elaborates each statement under `--build` and
classifies it credited/glue, quarantining whatever does not elaborate.

But that re-elaboration runs under the **single repo-wide pin**
(`leanprover/lean4:v4.30.0` + the mathlib rev `c5ea0035…` in `lake-manifest.json`, per
[ADR-002](ADR-002-Lean4-Mathlib-Pinned-Release-Tags.md)). Benchmark suites are authored
against their **own**, often-older mathlib — miniF2F-lean4 and CombiBench are both
pinned to **v4.24**. Re-elaborating at v4.30 silently quarantines every statement that
hit an API rename/removal in the intervening versions. Concrete evidence from M8 (#6371):

- `putnam-1966-b5` → `Finset.toSet` no longer exists (renamed to `↑`/`Finset.coe`);
- `brualdi-ch12-37` → `Unknown identifier Q_3.dominationNum`;
- the bulk of IMOLean 2022–25 (14/32 quarantined), plus assorted CombiBench items.

So the imported yield understates each suite's true size and is biased toward whichever
problems survive *our* pin's drift — exactly the "mathlib-pin quarantine rate" residue
ADR-092 flagged. For an honest, comparable benchmark, a suite should be evaluable **at
the mathlib version it was written for**.

**Two root causes, both verified in code.** (a) `--build` calls
`_probe_verdict(text, Path(args.root))` → `probe(..., root=root)`
(`tools/sourcing/check_triviality.py`), whose `_run_probe()` runs `lake env lean` with
`cwd=<repo root>`, so the toolchain/mathlib come from the repo regardless of the
`--mathlib`/`--toolchain` passed. (b) The recorded `mathlib≜…` in
`targets/<suite>/{skeleton,target}.aisp` is whatever `--mathlib` the operator passed —
for the existing suites that was the repo pin, not the native rev — so the suite
metadata currently misstates its own pin.

The `target.aisp`/`skeleton.aisp` schema **already** records `toolchain≜…;mathlib≜…`
per suite, and `tools/leaderboard/registered_targets.py` already surfaces it as
`mathlib_pin`. The field exists; nothing honours it. This ADR makes it authoritative.

A strong in-repo precedent already exists: archive packages
(`packages/unsorry-archive-NNNN/`) are each a self-contained lake project with their own
`lean-toolchain` + `lakefile.toml` + `lake-manifest.json`, scaffolded by
`tools/archive/apply.py::cut()` and built in Gate A
(`tools/gate_a/archive_packages.py`) with `lake exe cache get` then `lake build --wfail`
at `cwd=<package>`. Per-suite verification is "do for benchmark suites what we already
do for archive packages."

## WH(Y) Decision Statement

**In the context of** a ratified segregated benchmark track (ADR-092) whose importer
re-elaborates every suite under the single repo-wide mathlib pin, an `.aisp` schema that
already records a per-suite `toolchain≜…;mathlib≜…` that nothing honours, and an
archive-package precedent for per-directory lake projects pinned independently of the
repo,

**facing** the choice between *porting* each suite to the repo pin (today's implicit
`--build` behaviour — quarantining whatever does not elaborate) and *evaluating* each
suite at the version it was written for,

**we decided for** treating a registered suite's `(toolchain, mathlib rev)` as
**authoritative**: ingestion and verification both run in a **suite-scoped lake project**
pinned to that pair (reusing the archive-package scaffolding), benchmark proofs verify
and record in a **suite-scoped track kernel-checked at the suite's pin** (extending the
ADR-092 `cohort:benchmark` segregation), and `./swarm/run.sh --goal <slug>` selects the
suite's toolchain so the swarm proves each benchmark goal in the right context,

**and neglected** (a) **porting statements to the repo pin** — lower infra cost, but it
loses problems and is unfaithful to the original benchmark; (b) a **template-substituted
`lake-manifest.json`** (substitute only the mathlib rev) — fragile, because transitive
dependency revs differ per mathlib version, so a hand-edited manifest will not resolve;
(c) landing benchmark proofs in `UnsorryLibrary` — impossible, the library is one pin;
(d) a bespoke per-suite scoring scheme — conform to the ADR-092 verified-pass@k canon,

**to achieve** drift quarantines that drop to ~0 for native-pin suites — an honest,
comparable measure of each suite's true yield — while preserving the founding soundness
line,

**accepting that** the swarm now maintains **N mathlib binary caches** (one per supported
pin) at N× disk (mitigated by the FRO `lake exe cache get`, which has published caches
for release-tag pins); that "0 false positives (kernel-verified)" is now asserted **at
the suite's pin** (sound under ADR-048/049 — the Lean kernel is the sole oracle at *any*
mathlib version, since the rev affects only *which statements elaborate*, not whether a
proof is trusted); and that the operator must supply each suite's
`lake-manifest.json` (decision A below) rather than the tool fetching it.

## Decision detail

1. **Per-suite pin is authoritative.** A suite's `target.aisp`/`skeleton.aisp`
   `toolchain≜…;mathlib≜…` records its **native** `(toolchain, concrete mathlib rev)`.
   The importer records the native pin (not the repo pin); `registered_targets.py`
   surfaces it per suite as `mathlib_pin`.
2. **Suite-scoped verifier context.** Ingestion materialises a suite-scoped lake project
   `targets/<suite>/_verify/{lean-toolchain, lakefile.toml, lake-manifest.json}` (a
   leading-underscore dir, inert to the repo `lakefile.toml` globs and to
   `skeleton-validate`), reusing the `archive/apply.py::cut()` template. `--build`
   elaborates/builds with `cwd=_verify`, not the repo root. A **pin guard** aborts if
   the verifier-context rev ≠ the recorded `--mathlib`, so metadata and the context that
   classified the suite can never diverge.
3. **Real-build hardening.** `--build` runs a real `lake env lean` of the **actual
   statement** (not only the `foralltype` battery proxy), closing the probe-vs-build gap
   that let 4 non-building goals through in #6371. A genuine elaboration failure
   quarantines (reason: "does not build under the suite pin"); the battery probe then
   classifies the survivors glue/credited. `skeleton_validate._check_build` carries the
   same repo-pin bug and is fixed in the same place.
4. **Segregated verification at the suite pin.** Benchmark proofs cannot land in
   `UnsorryLibrary` (one pin), so each suite gets a verification package built in Gate A
   at its pin: `lake exe cache get` (that pin's FRO cache) → `lake build --wfail` →
   axiom audit. Reuses the generalised `gate_a/archive_packages.py` validator. Proofs are
   recorded under `cohort:benchmark` (ADR-092) with the pin surfaced per suite; they stay
   excluded from the organic leaderboard/`_score`.
5. **`run.sh --goal` toolchain selection.** When `--goal <slug>` resolves to a
   benchmark-suite goal, the prover builds/verifies in the suite-scoped project at the
   suite pin; non-benchmark goals keep the repo-pin path unchanged.
6. **Manifest provenance (decision A).** The suite `lake-manifest.json` is
   **operator-supplied** (`--manifest`), obtained once by `lake update` in a throwaway
   project at the native toolchain. Deterministic and hermetic; no network in the tool.
   `--mathlib` is the **concrete rev** (not a symbolic inputRev) so the pin guard is
   exact.

## Consequences

- **Positive.** Native-pin suites ingest at full yield (drift quarantines → ~0); the
  benchmark becomes an honest, comparable measure; the per-suite `.aisp` pin field stops
  lying; all of it reuses the ratified archive-package + intake + ADR-092 machinery.
- **Cost.** N mathlib binary caches (one per supported pin), N× disk; a suite-scoped
  verifier-context scaffolder (`tools/intake/verifier_context.py`); a generalised
  pinned-package Gate A leg; per-suite toolchain selection in the swarm runner. Gate A
  and `swarm/` are CODEOWNERS surfaces → those PRs need human code-owner review
  (ADR-019).
- **Residue.** Operator must supply each suite's `lake-manifest.json`; the
  statement-fidelity caveat from ADR-092 is unchanged (a wrong-but-agreed formalisation
  still passes — the false-statement filter remains mandatory); existing suites recorded
  under the repo pin need a one-time metadata re-pin to their true native rev (tracked
  separately, not blocking this ADR).

## References

| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Segregated Benchmark Track — verified pass@k | Decision | ADR-092-Segregated-Benchmark-Track.md |
| REF-2 | registered-targets.json contract + pass@k + segregation | Spec | specs/SPEC-092-A-Benchmark-Track.md |
| REF-3 | Problem Admission & the Skeleton Intake Pipeline | Decision | ADR-081-Problem-Admission-And-Intake-Pipeline.md |
| REF-4 | Sponsor-Registered Targets & Obligation-Discharge Credit | Decision | ADR-078-Sponsor-Registered-Targets-And-Obligation-Discharge-Credit.md |
| REF-5 | Platform Generalisation & the Gating Invariant | Decision | ADR-080-Platform-Generalisation-And-Domain-Neutrality.md |
| REF-6 | Verify-On-Ingest (kernel re-verify) | Decision | ADR-048-Verify-On-Ingest.md |
| REF-7 | Decentralised CI — kernel is the sole oracle | Decision | ADR-049-Decentralised-CI-Runner-Architecture.md |
| REF-8 | Lean4/Mathlib Pinned Release Tags | Decision | ADR-002-Lean4-Mathlib-Pinned-Release-Tags.md |
| REF-9 | Proof Archive Blocks (per-directory pinned lake project precedent) | Decision | ADR-041-Proof-Archive-Blocks.md |
| REF-10 | CI Supply-Chain Protection (CODEOWNERS trust surfaces) | Decision | ADR-019-CI-Supply-Chain-Protection.md |
| REF-11 | Per-suite mathlib pin for benchmark ingestion | Issue | #6381 |
| REF-12 | This decision's implementation contract | Spec | specs/SPEC-099-A-Per-Suite-Mathlib-Pin-For-Benchmark-Ingestion.md |

## Status History

| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers (#6381) | 2026-06-25 |
