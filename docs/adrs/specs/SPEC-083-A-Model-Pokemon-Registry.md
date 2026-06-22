# SPEC-083-A: Model → Pokémon Registry

Implements **[ADR-083](../ADR-083-Model-Pokemon-Registry-And-Operational-Tasks.md)**.
Living document — evolves with the implementation.

## 1. Artifact: `docs/metrics/model-registry.json`

Single source of truth; served by Pages and read by the guild. Shape:

```jsonc
{
  "schema_version": 1,
  "generated_at": "2026-06-22T00:00:00Z",   // ISO-8601 UTC
  "models": [
    {
      "provider_model": "claude / opus",     // exact join key to leaderboard-ui.json models[].provider_model
      "slug": "claude-opus",                 // == slugify(provider_model); the /math/models/<slug> route key
      "pokemon": {
        "name": "Alakazam",
        "dex_id": 65,                         // national dex id; must match name in the manifest
        "sprite_url": "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/65.png",
        "description": "Its brain can outperform a supercomputer..."  // PokéAPI species flavour text (cleaned)
      },
      "research": {
        "classification": "open|closed|n/a",
        "publisher": "Anthropic",
        "country": "United States",
        "parameter_size": "undisclosed",      // or "70B", "n/a", ...
        "license": "proprietary",
        "canonical_url": "https://www.anthropic.com/claude"  // HF model page if open; official site if closed
      },
      "profile": "Alakazam's deliberate, supercomputer-grade intellect mirrors Opus...",
      "provenance": {
        "assigned_by": "housekeeping",
        "assigned_with": "opus",
        "sources": ["https://..."],
        "assigned_at": "2026-06-22T00:00:00Z"
      }
    }
  ]
}
```

`slug`, `pokemon.sprite_url` and `pokemon.description` are **derived deterministically** at
assignment (slug from `provider_model`; sprite from the dex id; description from PokéAPI) so a
model can never hallucinate a sprite or flavour text.

## 2. Selection criteria (validator + agent brief)

| Criterion | Enforced by | Rule |
|-----------|-------------|------|
| **Valid** | `validate.is_valid` | `(name, dex_id)` matches a real Pokémon in `pokedex.json`; `sprite_url == sprite_url(dex_id)`. |
| **Unique** | `validate_registry` | `provider_model`, `slug`, `pokemon.dex_id`, and case-insensitive `pokemon.name` are each unique across the registry. *Once chosen, no other model may take that Pokémon.* |
| **Complete** | `validate_registry` | All `research` fields present & non-empty; `classification ∈ {open, closed, n/a}`; `canonical_url` is an `http(s)` URL; `profile` non-empty; `provenance.sources` non-empty. |
| **Appropriate** | the agent (`profile`) | Choice justified by the researched attributes; not machine-checkable. |

## 3. Tooling — `tools/model_registry/`

- `pokedex.py` — vendored manifest loader; `slugify`, `sprite_url`, `is_valid`, `display_name`,
  `fetch_flavor_text` (English species text, soft-hyphen wraps rejoined). Single source of the
  sprite-URL template (DRY).
- `pokedex.json` — national-dex `{id, name}` manifest; refreshed by `build_pokedex.py` (PokéAPI,
  User-Agent required).
- `registry.py` — `validate_registry`, `check_single_addition`, `assemble_entry`, `add_entry`,
  `unassigned`, `distribution_models`, `taken_*`.
- `__main__.py` — CLI (exit 0 clean / 1 violations / 2 error):
  - `validate <path>` — full validation (the CI gate).
  - `check-added --base B --head H` — head valid, **exactly one** model added, none removed/modified.
  - `unassigned --distribution leaderboard-ui.json --registry model-registry.json` — the work-list.
  - `assign --registry R --provider-model PM --candidate C --assigned-by … --assigned-with … --assigned-at …`
    — assemble from a research candidate, validate as a single addition, write.
- `tests/` — pytest, stdlib-only, offline (uses the vendored manifest).

## 4. Operational task — `swarm/housekeeping.sh`

Run by `run.sh` as the first work package (governed swarm only; `UNSORRY_HOUSEKEEPING=0` to skip).
Per invocation, for up to `UNSORRY_REGISTRY_MAX` (default **1**) unnamed models:

1. `unassigned` → next model `PM`.
2. `build_prompt PM <taken>` → `claude -p` (tools: WebSearch, WebFetch, Read) → JSON candidate
   `{pokemon{name,dex_id}, research{…}, profile, sources[]}`; retried up to `UNSORRY_REGISTRY_RETRIES`.
3. `assign` assembles + validates the single addition + writes `model-registry.json`.
4. Branch `chore/registry-<slug>`, commit `chore(registry): name <PM> as <Pokémon>`, push, open a PR,
   enable auto-merge.

`--self-test` exercises the pure helpers (slug/branch/commit/prompt) with no network, git or agent.

## 5. CI gate — `.github/workflows/model-registry-gate.yml`

On PRs/pushes touching the registry, the tool, or the workflow: run `pytest tools/model_registry`,
`validate` the artifact, and (on PRs that **modify** an existing registry) `check-added` against the
base — enforcing one Pokémon per PR. The PR that first introduces the file (the seed) is exempt from
the single-addition rule. Always reports (short-circuits vacuously when no registry paths change).

## 6. Seed

The initial `model-registry.json` names every model currently in the distribution with
`verified_proofs > 0` (11 models), using the same research + selection process the housekeeping task
automates. Notable mapping: the Claude tier ladder is the Abra evolutionary line —
`claude / unknown` → Abra, `claude / sonnet` → Kadabra, `claude / opus` → Alakazam.
