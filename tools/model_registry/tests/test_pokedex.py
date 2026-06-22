"""Tests for the shared Pokédex helpers (ADR-083).

These run offline against the vendored ``pokedex.json`` — no network.
"""
from __future__ import annotations

from tools.model_registry import pokedex


def test_manifest_loads_full_national_dex() -> None:
    manifest = pokedex.load_manifest()
    assert len(manifest) >= 1025
    assert manifest[1] == "bulbasaur"
    assert manifest[65] == "alakazam"


def test_sprite_url_is_front_default_path() -> None:
    assert pokedex.sprite_url(65) == (
        "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/65.png"
    )


def test_slugify_collapses_separators() -> None:
    assert pokedex.slugify("claude / opus") == "claude-opus"
    assert pokedex.slugify("python / sympy") == "python-sympy"
    assert pokedex.slugify("openai / jackcloudman/Leanstral-2603-GGUF") == (
        "openai-jackcloudman-leanstral-2603-gguf"
    )
    assert pokedex.slugify("  Spaced  ") == "spaced"


def test_display_name_titlecases_each_part() -> None:
    assert pokedex.display_name("alakazam") == "Alakazam"
    assert pokedex.display_name("mr-mime") == "Mr-Mime"


def test_is_valid_accepts_real_pokemon_case_insensitively() -> None:
    assert pokedex.is_valid(65, "Alakazam")
    assert pokedex.is_valid(65, "alakazam")
    assert pokedex.is_valid(132, "Ditto")


def test_is_valid_rejects_mismatched_or_unknown() -> None:
    assert not pokedex.is_valid(66, "Alakazam")  # wrong id
    assert not pokedex.is_valid(65, "Machamp")  # wrong name
    assert not pokedex.is_valid(99999, "Notamon")  # unknown id


def test_clean_flavor_rejoins_soft_hyphen_wraps() -> None:
    # Soft hyphen (U+00AD) + newline marks a hyphenated wrap → rejoin, no space.
    raw = "Its brain can out­\nperform a super­\ncomputer.\fEnd."
    assert pokedex._clean_flavor(raw) == (
        "Its brain can outperform a supercomputer. End."
    )
