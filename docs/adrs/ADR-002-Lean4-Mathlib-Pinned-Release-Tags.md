# ADR-002: Lean 4 + mathlib4 Pinned to Release Tags

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-002 |
| **Initiative** | unsorry Gate A readiness |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-10 |
| **Status** | Accepted |

## WH(Y) Decision Statement
**In the context of** unsorry's verified proof library, where the design doc selects Lean 4 with mathlib4 as the research domain and Gate A requires a full `lake build` in CI on every PR,
**facing** the fact that building mathlib from source takes hours per CI run while a prebuilt binary cache restores in minutes, and that only mathlib release tags carry both a guaranteed published cache and a stable (non-rc) Lean toolchain,
**we decided for** Lean 4 with mathlib4 as a dependency from day one, with the toolchain pinned exclusively to mathlib release tags (currently v4.30.0): `lean-toolchain` copied verbatim from the mathlib tag, the lakefile requiring mathlib at `rev` = the same tag, `lake-manifest.json` committed, CI fetching prebuilt oleans via `lake exe cache get` and never building mathlib from source, and toolchain/mathlib bumps performed only together in a dedicated PR,
**and neglected** starting with Lean core + Batteries only and adding mathlib later, tracking mathlib master, and building mathlib from source in CI,
**to achieve** a Gate A that is affordable on every PR, byte-for-byte reproducible builds across heterogeneous swarm agents, and the full mathlib library available to the Phase-1 backlog from the first goal,
**accepting that** the library lags mathlib master by up to a release cycle, CI must manage a multi-gigabyte olean cache, and `--wfail` strictness interacts with deprecation warnings at bump time (handled inside the dedicated bump PR).

## Context

The design doc (docs/proposals/distributed-research-swarm-plan.md) selects formal mathematics in Lean 4, with mathlib as a dependency, as the swarm's research domain. The Lean kernel is the sole truth oracle, and Gate A — a full `lake build` on every PR, rejecting `sorry`, `admit`, and non-standard axioms — is the trust boundary that makes contribution by untrusted, intermittent agents safe. Everything else in the architecture assumes Gate A runs cheaply and on every PR.

That assumption holds only if mathlib arrives in CI as a binary artifact. Compiling mathlib from source takes hours; restoring its prebuilt oleans via `lake exe cache get` takes minutes. The Lean community publishes guaranteed caches for mathlib release tags; arbitrary intermediate commits carry no such guarantee. Release tags are also the only revisions that pin a stable Lean toolchain: verified at decision time, mathlib master pins `leanprover/lean4:v4.31.0-rc2`, a release candidate, while the latest release tag v4.30.0 pins the stable v4.30.0 toolchain.

Reproducibility carries unusual weight in this project. The swarm consists of heterogeneous agents on different machines, all of which must verify proofs against an identical toolchain and library state — a proof that compiles on one agent's machine must compile in CI and on every other agent's machine. Pinning the entire dependency surface to a single named release tag, with the manifest committed, makes the build environment a deterministic function of the repository contents alone, consistent with the design principle that the repository is the single source of truth.

The alternative of deferring mathlib entirely was considered and rejected: the Phase-1 backlog of 20–50 known-true theorems is only interesting if statements can draw on mainstream mathematics, and the published design doc names mathlib as the dependency and upstreaming target. Deviating from it would require revising the design rather than implementing it.

## Options Considered

### Option 1: Lean 4 + mathlib4 from day one, pinned to mathlib release tags (Selected)
The toolchain file is copied verbatim from the chosen mathlib tag, mathlib is required at the same tag, and the lockfile is committed; CI restores prebuilt oleans and never compiles mathlib. Pros: Gate A runs in minutes on every PR; stable (non-rc) toolchain; identical, reproducible environment for every agent and for CI; full mathlib available to the Phase-1 backlog immediately; bumps are atomic and reviewable in a single dedicated PR. Cons: the library trails mathlib master by up to a release cycle; CI must fetch and cache a multi-gigabyte artifact; deprecation warnings surfacing under `--wfail` must be resolved at each bump.

### Option 2: Lean core + Batteries only at first, mathlib later (Rejected)
Lighter CI with no large cache to manage. Rejected because it deviates from the published design doc, which selects mathlib as the dependency and upstreaming target, and because it restricts the Phase-1 backlog to elementary statements provable from a near-empty library — undermining the goal-selection and compounding mechanisms the plan is built around. Deferring mathlib also means paying the integration cost later, after the swarm contract and CI gates have calcified around its absence.

### Option 3: Track mathlib master (Rejected)
Freshest library content. Rejected because master pins release-candidate Lean toolchains (v4.31.0-rc2 at decision time), carries no guaranteed published cache for arbitrary commits, and moves continuously — breaking reproducibility across agents and making "does it build" depend on when an agent last pulled rather than on the repository state.

### Option 4: Build mathlib from source in CI (Rejected)
Removes any dependence on published caches. Rejected as structurally unaffordable: a source build takes hours per run, and Gate A must run on every PR from every agent. The swarm's economics assume verification is cheap; this option makes it the dominant cost.

## Dependencies
| Relationship | ADR ID | Title | Notes |
|--------------|--------|-------|-------|
| Depends On | ADR-001 | Adopt Development Protocols | Protocols establish the ADR/spec/CI discipline under which this pin is maintained, including the latest-stable-dependency rule the release-tag policy instantiates |
| Relates To | ADR-005 | Autonomous Merge Policy | Autonomous merge on Gate A green is only viable because the pinned cache keeps Gate A fast and deterministic |

## References
| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Distributed Autonomous Research Swarm: Architecture and Plan | Design document | docs/proposals/distributed-research-swarm-plan.md |
| REF-2 | mathlib4 repository (release tags, toolchain pins, olean cache) | External dependency | https://github.com/leanprover-community/mathlib4 |
| REF-3 | SPEC-002-A — Toolchain Pinning and CI Cache | Specification | lands with its implementation PR |

## Status History
| Status | Approver | Date |
|--------|----------|------|
| Accepted | unsorry maintainers | 2026-06-10 |
