# ADR-083: The Model → Pokémon Registry and Swarm Operational Tasks

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-083 |
| **Initiative** | unsorry — broadening swarm work beyond proofs; gamifying the model distribution |
| **Proposed By** | unsorry maintainers (companion to guild issue agenticsnz/unsorry-guild#20) |
| **Date** | 2026-06-22 |
| **Status** | Accepted |

## Context

The leaderboard publishes a **model distribution** (`docs/metrics/leaderboard-ui.json` →
`models[]`): one row per `provider/model` that has run proofs (e.g. `claude / opus`,
`python / sympy`). Today those rows are anonymous strings — no identity, no depth, nothing to
click through to. The guild wants to gamify them: give each model a memorable **Pokémon**
identity (sprite, description, a researched profile) and a model page.

More interestingly, the swarm has only ever done **one kind of work** — discharge an open Lean
goal. Producing and maintaining these identities is *not* a proof; it is **operational** work
(research a model, pick a unique Pokémon, write a record). This ADR introduces that second class
of work and the artifact it produces.

The fixed end of the funnel the guild consumes is the existing metrics-artifact contract: a JSON
file under `docs/metrics/`, served by Pages and read by the guild with a raw-GitHub fallback.

## WH(Y) Decision Statement

**In the context of** a swarm that publishes an anonymous model distribution and performs only
proof work,

**facing** a request to give each model a unique, researched Pokémon identity *and* a desire to
let the swarm take on maintenance work it can pick up like any other task,

**we decided for** a new class of **operational work package** — a `swarm/housekeeping.sh` script
that `run.sh` runs **first**, before the proving arms, which for each unnamed model researches it
(open/closed source, publisher, country, parameter size, canonical link) and assigns it a unique
Pokémon, publishing the result to `docs/metrics/model-registry.json` as the single source of truth
the guild reads — with the **atomic unit being one Pokémon for one model = exactly one PR**, gated
by a deterministic validator (schema · Pokémon validity · uniqueness · completeness),

**and neglected** (a) hand-curating identities in a static file (does not scale, goes stale, not
swarm work); (b) a live frontend-side PokéAPI lookup per render (couples the guild to a third-party
API at request time and cannot carry the researched profile); (c) modelling naming as a claimable
proof-style goal with `claims/` + Gate B (heavyweight; naming is not a proof and needs no claim
TTLs); (d) per-record registry files aggregated by a generator (the operational task is
operator-driven and serial, so a single committed file with a one-entry-per-PR gate is simpler and
race-free),

**to achieve** a self-maintaining, swarm-generated registry that broadens what the swarm does,
keeps the guild a pure read-only consumer, and assigns each model a durable, unique identity with a
human-legible rationale,

**accepting that** the registry is a single committed file edited one entry per PR (so naming is
serialised — by design, one Pokémon per work packet); that a Pokémon name, once assigned, is
permanently reserved (uniqueness is monotone); and that the *appropriateness* of a choice depends on
the agent's research and is not machine-checkable (only validity, uniqueness and completeness are).

## Decision detail

- **Operational task category.** `swarm/housekeeping.sh` is the first such task: invoked by `run.sh`
  before `dispatcher`/`sourcer`/`prover`, governed-swarm only (it opens upstream PRs, which a fork
  cannot). Disabled with `UNSORRY_HOUSEKEEPING=0`.
- **Resolve-before-proving guarantee.** Housekeeping **drains every unnamed model** and run.sh
  **blocks** on it — it does not start any proving/dispatch/sourcing arm unless every distribution
  model has a Pokémon. So naming is never starved by proof work.
- **Work-packet rule.** One model → one Pokémon → one PR. The drain is serialised (`UNSORRY_REGISTRY_MAX`
  default 0 = all): each model is named, opened as one PR, and settled onto main before the next, so
  the single-file registry never sees concurrent edits and uniqueness always holds.
- **Selection criteria** (SPEC-083-A): *valid* (real Pokémon in the vendored Pokédex manifest),
  *unique* (name + dex id + slug not already taken), *appropriate* (justified by research; captured
  in `profile`), *complete* (all research fields present; `canonical_url` is the Hugging Face page
  for open models, the official site for closed ones).
- **Provenance.** Each entry records who named it: `assigned_with` (the naming model in
  `provider_model` form, joining to *its* Pokémon) and `contributor` (the owning swarm contributor's
  GitHub handle).
- **Validator + gate.** `python3 -m tools.model_registry` (stdlib + pytest only, mirroring Gate B,
  ADR-003) enforces the mechanical criteria; `.github/workflows/model-registry-gate.yml` runs it on
  registry PRs and enforces the one-new-entry diff. Assignment PRs enable auto-merge.

## Consequences

- The guild consumes one new artifact (`model-registry.json`) via the existing fetch contract; no
  change to the leaderboard pipeline. See guild ADR-027.
- A vendored `tools/model_registry/pokedex.json` (national-dex name↔id) is the single source of
  truth for Pokémon validity and sprite-URL derivation; refreshed by `build_pokedex.py`.
- Future operational tasks (other housekeeping) can follow the same shape: a `swarm/*.sh` package
  run by `run.sh`, a `tools/*` validator, a published artifact.

## Dependencies

- Consumes `docs/metrics/leaderboard-ui.json` (`models[]`) — the leaderboard pipeline.
- Reuses the deterministic-validator discipline of **ADR-003** (Gate B) and the changelog-fragment
  flow of **ADR-040**.
- Paired with guild **ADR-027** (consumption: model pages + sprites).
