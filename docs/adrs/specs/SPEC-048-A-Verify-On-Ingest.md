# SPEC-048-A: Verify-on-Ingest — Archive Provenance Validation

Implements: [ADR-048](../ADR-048-Verify-On-Ingest.md) · Status: Living · Updated: 2026-06-15

## Behaviour

A proof is kernel-verified once, by Gate A, at the PR that introduces it (incremental replay,
ADR-033). When that proof is later moved into an archive package, Gate A validates **provenance +
packaging**, not soundness from scratch: it proves the archived proof module is byte-identical to the
already-verified version and that the package still compiles — and it does **not** re-run
`leanchecker` (which loads the package's full mathlib image and OOM-killed memory-bound runners,
#764).

## Implementation

### Provenance — `tools/gate_a/archive_packages.py`

- `archive_proof_provenance(repo_root, package_root, base, runner)`: for every tracked proof module
  under `<package>/library/` at `HEAD` (`git ls-tree -r --name-only HEAD`), compute its git blob hash
  and require it to equal a **prior verified version**:
  - the **base active** module — `<base>:library/Unsorry/<X>.lean` (being archived in this PR), or
  - the **base archived** copy — `<base>:<package>/library/Unsorry/<X>.lean` (already frozen).
  - If neither exists or none matches, the module is rejected (net-new or altered proof content that
    was never kernel-replayed). Returns non-zero → gate fails.
  - Git blob hashes are content hashes, so equality means byte-identity.
- `validate_archive_package(..., base=None)` runs `archive_proof_provenance` early when `base` is
  given, then forbidden-token + Gate B + statement-binding + `lake build --wfail` (packaging sanity)
  + cleanup. **No `leanchecker` replay.**
- `validate_changed(root, base, ...)` passes `base` through, so PR runs (`validate-changed --base
  <PR base>`) enforce provenance. A base-less push run skips provenance — the package's introducing
  PR already enforced it and the package is immutable since.

### Goal statements

Archived goal statements remain pinned by ADR-018 (`check_goal_immutability`, in `gate-a-prepare`).
Provenance (this spec) covers the proof modules; ADR-018 covers the goal statements.

### Workflow — `.github/workflows/gate-a.yml`

`gate-a-archive` runs `archive_packages validate-changed --base <PR base>`. With no kernel replay it
no longer needs swap or a large replay runner; it runs on the `namespace-profile-unsorry-prepare` lane.

## Safety

Lean soundness is unchanged: every proof was kernel-replayed by the trusted pipeline when active,
under its pinned toolchain/mathlib, and provenance proves the archived bytes are exactly that
artifact. The trust boundary is "CI verified this exact artifact + it is immutable," never a prover's
attestation. The residual risk is bookkeeping (knowing the archived file is the verified one) — closed
by the git-blob-identity check. A context change (toolchain/mathlib/lake/checker, ADR-033) still forces
re-verification; a scheduled full replay is the defense-in-depth backstop.

## Acceptance criteria

- A byte-identical active→archive move passes `archive_proof_provenance`.
  (`test_archive_provenance_accepts_byte_identical_move`.)
- An archived proof whose bytes differ from the verified active version is **rejected**, even if the
  goal statement is unchanged. (`test_archive_provenance_rejects_tampered_proof`.)
- A net-new proof appearing only in an archive (no verified base) is **rejected**.
  (`test_archive_provenance_rejects_net_new_proof`.)
- Archive validation never invokes `lake env leanchecker`.
  (`test_validate_archive_package_does_not_replay`.)
- `lake build --wfail` packaging sanity is retained.
  (`test_validate_archive_package_runs_soundness_steps`.)
