The client-side swarm scripts now **auto-install the Lean build tool** (`lake`)
when it is missing instead of aborting. A new shared bootstrap
`swarm/lib/ensure_lake.sh` (`ensure_lake`) puts the standard toolchain locations on
`PATH` and, if `lake` is still absent, installs **elan** (the Lean toolchain
manager) non-interactively — the pinned toolchain then lands from `lean-toolchain`
on first build (ADR-002, never building mathlib). `swarm/agent.sh` and
`tools/independent_check/setup.sh` route their `lake` dependency through it, so a
bare machine that previously failed with `lake: command not found` (and silently
disabled the independent check) now bootstraps the toolchain and proceeds. Mirrors
the existing `ensure_cargo` Rust bootstrap; idempotent, non-invasive
(`--no-modify-path`), and `ELAN_INIT_URL`-overridable for mirrors
([ADR-097](docs/adrs/ADR-097-Auto-Install-Lake-Toolchain.md),
[SPEC-097-A](docs/adrs/specs/SPEC-097-A-Auto-Install-Lake-Toolchain.md)).
