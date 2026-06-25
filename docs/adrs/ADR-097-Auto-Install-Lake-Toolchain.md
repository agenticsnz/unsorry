# ADR-097: Client-Side Swarm Scripts Auto-Install the Lean Build Tool (`lake`)

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-097 |
| **Initiative** | contributor onboarding / swarm self-sufficiency |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-25 |
| **Status** | Proposed |

## Context

A contributor ran `./swarm/run.sh --goal putnam-v1-suite` on a machine where the
Lean build tool `lake` was not on `PATH`. The run degraded twice:

```
./tools/independent_check/setup.sh: line 73: lake: command not found
[run …] independent check: dependency setup failed (needs lake + cargo) — proceeding WITHOUT it
```

`lake` is not a standalone binary — it ships with a Lean toolchain, which is
installed and version-multiplexed by **elan** (the Lean toolchain manager). The
project already assumes elan is the install path: CLAUDE.md says "Toolchain
auto-installs via elan from `lean-toolchain`", CI uses `leanprover/lean-action`
(which installs elan), and `swarm/agent.sh` already prepends `~/.elan/bin` to
`PATH` before probing. But the *client-side* scripts had **no path to install
elan when it is entirely absent** — they only normalised `PATH` and then failed
hard (`require_cmd lake` → `die_config`) or skipped a feature.

This is inconsistent with a sibling dependency in the very same flow:
`tools/independent_check/setup.sh` already **auto-installs Rust/cargo** via
`ensure_cargo` ("`run.sh --independent-check` must be fully self-contained — so if
Rust/cargo … is missing, install it via rustup non-interactively"). `lake` — the
*more* fundamental dependency, needed by proving itself, not just the advisory
checker — had no equivalent. So a bare machine could bootstrap the optional
nanoda checker's Rust toolchain but not the mandatory Lean one.

## WH(Y) Decision Statement

**In the context of** the client-side swarm scripts (`swarm/run.sh` →
`swarm/agent.sh` and `tools/independent_check/setup.sh`), which must run on a
contributor's bare machine and already auto-install Rust via `ensure_cargo`,

**facing** the fact that `lake` (provided by an elan-managed Lean toolchain) was
*assumed present* — its absence aborted the swarm (`require_cmd lake` →
`die_config`) or silently disabled the independent check — even though the
canonical, project-blessed way to get `lake` (elan, driven by `lean-toolchain`,
ADR-002) is a one-line non-interactive install,

**we decided for** a single shared, idempotent `ensure_lake` bootstrap
(`swarm/lib/ensure_lake.sh`) that puts the standard toolchain locations on `PATH`,
and if `lake` is still missing installs elan via its official non-interactive
installer (`--default-toolchain none`, so the pinned toolchain still lands from
`lean-toolchain` on first build, ADR-002) — routing **every** client-side `lake`
dependency through it (replacing the two `require_cmd lake` sites in `agent.sh`
and guarding the `lake build` in `setup.sh`),

**and neglected** (a) keeping the hard-fail and documenting "install elan
yourself" — rejected: it is exactly the friction `ensure_cargo` already removed
for the sibling dependency, and inconsistent with CLAUDE.md's "toolchain
auto-installs via elan"; (b) duplicating an inline installer in each script —
rejected by DRY (protocol §12); (c) bundling/vendoring a Lean toolchain in the
repo — rejected: huge, platform-specific, and it would bypass the `lean-toolchain`
pin (ADR-002); (d) installing a *default* toolchain at elan-install time —
rejected: it would pull a toolchain the repo may not use and duplicate the
per-directory selection elan already does from `lean-toolchain`,

**to achieve** a swarm that bootstraps its own mandatory Lean build tool on a bare
machine exactly as it already bootstraps Rust — `./swarm/run.sh` just works —
while preserving the toolchain pin, staying idempotent and non-invasive (no shell
profile edits; `PATH` is managed in-process), and degrading to a clear actionable
message only when the install genuinely cannot proceed (e.g. no `curl`),

**accepting that** the scripts now perform a network install (`curl … | sh`) of a
third-party toolchain manager as a side effect of a bare-machine run — the same
trust posture already accepted for `ensure_cargo`/rustup — and that an air-gapped
or curl-less host still needs a manual elan install (for which `ELAN_INIT_URL`
allows a private mirror).

## Consequences

- **Positive.** `./swarm/run.sh` is self-contained on a bare machine for its
  *mandatory* toolchain, not just the optional Rust one. The reported failure
  (`lake: command not found` → independent check disabled) no longer occurs; the
  Lean toolchain installs on first use and proving proceeds.
- **Positive.** One authoritative bootstrap (`swarm/lib/ensure_lake.sh`, DRY) for
  every client-side `lake` consumer; the `lean-toolchain` pin (ADR-002) is
  untouched because elan is installed with `--default-toolchain none`.
- **Positive.** Idempotent and non-invasive: a prior elan is just re-`PATH`'d; the
  user's shell profile is left untouched (`--no-modify-path`); hermetic self-tests
  cover the present / install-succeeds / no-curl / install-no-op paths with no
  network.
- **Negative / accepted.** A bare-machine run now downloads and executes a
  third-party installer (`elan-init.sh`) — a real supply-chain surface, but the
  same one already accepted for rustup in `ensure_cargo`, and pinned via
  `ELAN_INIT_URL` to the official host (overridable for a mirror).
- **Neutral.** This is a contributor-side convenience only. It does **not** touch
  any trusted gate: CI installs elan via `leanprover/lean-action` as before, and
  Gate A / Gate B are unchanged.

## References

| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | `ensure_lake` bootstrap spec | Specification | specs/SPEC-097-A-Auto-Install-Lake-Toolchain.md |
| REF-2 | mathlib pinned to release tags; toolchain via elan from `lean-toolchain` | Decision | ADR-002-Lean4-Mathlib-Pinned-Release-Tags.md |
| REF-3 | Phase 3 scoped-export + independent checker (the `setup.sh` that failed) | Decision | ADR-096-Phase3-Scoped-Export-Independent-Checker.md |
| REF-4 | Runner-pool segmentation & verification capacity (`run.sh` flow) | Decision | ADR-058-Runner-Pool-Segmentation-And-Verification-Capacity.md |
| REF-5 | CI supply-chain protection (trust surface; CODEOWNERS) | Decision | ADR-019-CI-Supply-Chain-Protection.md |
| REF-6 | elan — the Lean toolchain manager | External | https://github.com/leanprover/elan |

## Status History

| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-25 |
