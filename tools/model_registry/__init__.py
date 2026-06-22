"""Model → Pokémon registry tooling (ADR-083).

A *swarm operational task* assigns each model in the leaderboard's model
distribution a unique Pokémon identity. This package provides the deterministic,
stdlib-only pieces that support that task:

- :mod:`tools.model_registry.pokedex` — the vendored national-dex manifest plus
  shared sprite-URL and slug helpers (the single source of truth reused by the
  housekeeping script, the validator and the frontend-bound artifact).
- :mod:`tools.model_registry.registry` — load/validate the registry artifact
  (``docs/metrics/model-registry.json``): schema, uniqueness and completeness.
- ``python3 -m tools.model_registry`` — the CLI used by the CI gate.
"""
