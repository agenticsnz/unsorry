"""Tests for the registry validator and PR-gate logic (ADR-083).

The validator is the mechanical half of the selection criteria: *valid*,
*unique*, *complete*, *well-formed schema*. The "appropriate" criterion is the
agent's job and is not machine-checkable here.
"""
from __future__ import annotations

import copy

from tools.model_registry import registry


def _opus_entry() -> dict:
    return {
        "provider_model": "claude / opus",
        "slug": "claude-opus",
        "pokemon": {
            "name": "Alakazam",
            "dex_id": 65,
            "sprite_url": "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/65.png",
            "description": "Its brain can outperform a supercomputer.",
        },
        "research": {
            "classification": "closed",
            "publisher": "Anthropic",
            "country": "United States",
            "parameter_size": "undisclosed",
            "license": "proprietary",
            "canonical_url": "https://www.anthropic.com/claude",
        },
        "profile": "Alakazam's deliberate, supercomputer-grade intellect mirrors Opus.",
        "provenance": {
            "assigned_by": "agent-test",
            "assigned_with": "claude / opus",
            "contributor": "cgbarlow",
            "sources": ["https://www.anthropic.com/claude"],
            "assigned_at": "2026-06-22T00:00:00Z",
        },
    }


def _sonnet_entry() -> dict:
    return {
        "provider_model": "claude / sonnet",
        "slug": "claude-sonnet",
        "pokemon": {
            "name": "Kadabra",
            "dex_id": 64,
            "sprite_url": "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/64.png",
            "description": "It emits alpha waves from its body.",
        },
        "research": {
            "classification": "closed",
            "publisher": "Anthropic",
            "country": "United States",
            "parameter_size": "undisclosed",
            "license": "proprietary",
            "canonical_url": "https://www.anthropic.com/claude",
        },
        "profile": "The balanced mid-stage Kadabra suits the everyday Sonnet.",
        "provenance": {
            "assigned_by": "agent-test",
            "assigned_with": "claude / opus",
            "contributor": "cgbarlow",
            "sources": ["https://www.anthropic.com/claude"],
            "assigned_at": "2026-06-22T00:00:00Z",
        },
    }


def _registry(*entries: dict) -> dict:
    return {
        "schema_version": 1,
        "generated_at": "2026-06-22T00:00:00Z",
        "models": list(entries),
    }


def _violations(*entries: dict) -> list[str]:
    return registry.validate_registry(_registry(*entries))


# --- happy path -----------------------------------------------------------


def test_valid_registry_has_no_violations() -> None:
    assert _violations(_opus_entry(), _sonnet_entry()) == []


def test_empty_registry_is_valid() -> None:
    assert registry.validate_registry(_registry()) == []


# --- schema / completeness ------------------------------------------------


def test_missing_research_field_is_flagged() -> None:
    e = _opus_entry()
    del e["research"]["country"]
    assert any("country" in v for v in _violations(e))


def test_empty_description_is_flagged() -> None:
    e = _opus_entry()
    e["pokemon"]["description"] = "  "
    assert any("description" in v for v in _violations(e))


def test_missing_contributor_is_flagged() -> None:
    e = _opus_entry()
    del e["provenance"]["contributor"]
    assert any("contributor" in v for v in _violations(e))


def test_empty_profile_is_flagged() -> None:
    e = _opus_entry()
    e["profile"] = ""
    assert any("profile" in v for v in _violations(e))


def test_non_http_canonical_url_is_flagged() -> None:
    e = _opus_entry()
    e["research"]["canonical_url"] = "anthropic.com"
    assert any("canonical_url" in v for v in _violations(e))


def test_unknown_classification_is_flagged() -> None:
    e = _opus_entry()
    e["research"]["classification"] = "sometimes"
    assert any("classification" in v for v in _violations(e))


def test_classification_allows_open_closed_na() -> None:
    for value in ("open", "closed", "n/a"):
        e = _opus_entry()
        e["research"]["classification"] = value
        assert registry.validate_registry(_registry(e)) == []


# --- pokemon validity -----------------------------------------------------


def test_unknown_pokemon_is_flagged() -> None:
    e = _opus_entry()
    e["pokemon"]["dex_id"] = 66  # 65 is Alakazam, not 66
    e["pokemon"]["sprite_url"] = registry.pokedex.sprite_url(66)
    assert any("not a real Pokémon" in v or "Pokémon" in v for v in _violations(e))


def test_sprite_url_must_match_dex_id() -> None:
    e = _opus_entry()
    e["pokemon"]["sprite_url"] = registry.pokedex.sprite_url(1)
    assert any("sprite_url" in v for v in _violations(e))


def test_slug_must_equal_slugified_provider_model() -> None:
    e = _opus_entry()
    e["slug"] = "opus"
    assert any("slug" in v for v in _violations(e))


# --- uniqueness -----------------------------------------------------------


def test_duplicate_pokemon_dex_id_is_flagged() -> None:
    a, b = _opus_entry(), _sonnet_entry()
    b["pokemon"]["dex_id"] = 65
    b["pokemon"]["sprite_url"] = registry.pokedex.sprite_url(65)
    b["pokemon"]["name"] = "Alakazam"
    assert any("dex_id" in v or "already" in v for v in _violations(a, b))


def test_duplicate_pokemon_name_is_case_insensitive() -> None:
    a, b = _opus_entry(), _sonnet_entry()
    b["pokemon"]["name"] = "alakazam"  # same as a, different case
    b["pokemon"]["dex_id"] = 65
    b["pokemon"]["sprite_url"] = registry.pokedex.sprite_url(65)
    assert any("name" in v.lower() or "alakazam" in v.lower() for v in _violations(a, b))


def test_duplicate_slug_is_flagged() -> None:
    a, b = _opus_entry(), _sonnet_entry()
    b["slug"] = "claude-opus"
    b["provider_model"] = "claude-opus"  # keep slug==slugify so only dup trips
    assert any("slug" in v for v in _violations(a, b))


def test_duplicate_provider_model_is_flagged() -> None:
    a, b = _opus_entry(), _opus_entry()
    assert any("provider_model" in v for v in _violations(a, b))


# --- one-Pokémon-per-PR gate ---------------------------------------------


def test_check_added_accepts_exactly_one_new_model() -> None:
    base = _registry(_opus_entry())
    head = _registry(_opus_entry(), _sonnet_entry())
    assert registry.check_single_addition(base, head) == []


def test_check_added_rejects_zero_additions() -> None:
    base = _registry(_opus_entry())
    head = _registry(_opus_entry())
    assert any("exactly one" in v for v in registry.check_single_addition(base, head))


def test_check_added_rejects_two_additions() -> None:
    base = _registry(_opus_entry())
    head = _registry(_opus_entry(), _sonnet_entry(), _ditto_entry())
    assert any("exactly one" in v for v in registry.check_single_addition(base, head))


def test_check_added_rejects_modifying_existing_entry() -> None:
    base = _registry(_opus_entry())
    modified = _opus_entry()
    modified["pokemon"]["name"] = "Kadabra"
    modified["pokemon"]["dex_id"] = 64
    head = _registry(modified, _sonnet_entry())
    assert any("modif" in v.lower() or "changed" in v.lower() for v in
               registry.check_single_addition(base, head))


def test_check_added_rejects_removing_existing_entry() -> None:
    base = _registry(_opus_entry(), _sonnet_entry())
    head = _registry(_opus_entry())
    assert any("remov" in v.lower() for v in registry.check_single_addition(base, head))


def test_check_added_allows_reset_to_empty() -> None:
    # A deliberate reset (clear all entries) is exempt from append-only/one-add.
    base = _registry(_opus_entry(), _sonnet_entry())
    head = _registry()  # zero models
    assert registry.check_single_addition(base, head) == []


def test_check_added_rejects_invalid_new_entry() -> None:
    base = _registry(_opus_entry())
    bad = _sonnet_entry()
    bad["research"]["canonical_url"] = "not-a-url"
    head = _registry(_opus_entry(), bad)
    assert registry.check_single_addition(base, head) != []


def _ditto_entry() -> dict:
    return {
        "provider_model": "openrouter / unknown",
        "slug": "openrouter-unknown",
        "pokemon": {
            "name": "Ditto",
            "dex_id": 132,
            "sprite_url": "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/132.png",
            "description": "It can transform into anything.",
        },
        "research": {
            "classification": "closed",
            "publisher": "OpenRouter, Inc.",
            "country": "United States",
            "parameter_size": "varies (routed)",
            "license": "proprietary",
            "canonical_url": "https://openrouter.ai",
        },
        "profile": "A router that becomes any model — Ditto in essence.",
        "provenance": {
            "assigned_by": "agent-test",
            "assigned_with": "claude / opus",
            "contributor": "cgbarlow",
            "sources": ["https://openrouter.ai"],
            "assigned_at": "2026-06-22T00:00:00Z",
        },
    }


def test_helper_taken_sets() -> None:
    data = _registry(_opus_entry(), _sonnet_entry())
    assert registry.taken_dex_ids(data) == {64, 65}
    assert registry.taken_names(data) == {"alakazam", "kadabra"}
    assert registry.assigned_models(data) == {"claude / opus", "claude / sonnet"}


# --- work-list (housekeeping) --------------------------------------------


def test_unassigned_preserves_distribution_order_and_excludes_assigned() -> None:
    distribution = ["python / sympy", "claude / opus", "claude / sonnet"]
    data = _registry(_opus_entry())
    assert registry.unassigned(distribution, data) == [
        "python / sympy",
        "claude / sonnet",
    ]


def test_unassigned_empty_when_all_named() -> None:
    distribution = ["claude / opus"]
    assert registry.unassigned(distribution, _registry(_opus_entry())) == []


def test_distribution_models_reads_provider_model_in_order(tmp_path) -> None:
    path = tmp_path / "leaderboard-ui.json"
    path.write_text(
        '{"models":[{"provider_model":"a / b","verified_proofs":9},'
        '{"provider_model":"c / d","verified_proofs":1}]}',
        encoding="utf-8",
    )
    assert registry.distribution_models(path) == ["a / b", "c / d"]


def test_add_entry_appends_one_valid_entry() -> None:
    base = _registry(_opus_entry())
    new_data, violations = registry.add_entry(base, _sonnet_entry())
    assert violations == []
    assert new_data is not None
    assert registry.assigned_models(new_data) == {"claude / opus", "claude / sonnet"}


def test_assemble_entry_fills_authoritative_fields() -> None:
    candidate = {
        "pokemon": {"name": "Ditto", "dex_id": 132},
        "research": {
            "classification": "closed",
            "publisher": "OpenRouter, Inc.",
            "country": "United States",
            "parameter_size": "varies",
            "license": "proprietary",
            "canonical_url": "https://openrouter.ai/",
        },
        "profile": "A router that becomes any model.",
    }
    entry = registry.assemble_entry(
        "openrouter / unknown",
        candidate,
        assigned_by="agent-1",
        assigned_with="claude / opus",
        contributor="cgbarlow",
        assigned_at="2026-06-22T00:00:00Z",
        description_fn=lambda dex_id: f"flavour-for-{dex_id}",
    )
    assert entry["slug"] == "openrouter-unknown"
    assert entry["pokemon"]["sprite_url"] == registry.pokedex.sprite_url(132)
    assert entry["pokemon"]["description"] == "flavour-for-132"
    assert entry["provenance"]["contributor"] == "cgbarlow"
    assert entry["provenance"]["assigned_with"] == "claude / opus"
    # sources defaults to the canonical url when the candidate omits them.
    assert entry["provenance"]["sources"] == ["https://openrouter.ai/"]
    # the assembled entry passes full validation.
    assert registry.validate_registry(_registry(entry)) == []


def test_add_entry_rejects_duplicate_pokemon() -> None:
    base = _registry(_opus_entry())
    clash = _sonnet_entry()
    clash["pokemon"] = copy.deepcopy(_opus_entry()["pokemon"])  # Alakazam again
    new_data, violations = registry.add_entry(base, clash)
    assert new_data is None
    assert violations != []
