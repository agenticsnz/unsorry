"""Model → Pokémon registry: load + validate (ADR-083).

The registry artifact (``docs/metrics/model-registry.json``) is the single
source of truth the guild frontend reads. ``validate_registry`` is the
mechanical half of the selection criteria — *valid*, *unique*, *complete*,
*well-formed* — enforced by the CI gate. ``check_single_addition`` enforces the
work-packet rule: one Pokémon for one model per PR.
"""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from . import pokedex

#: A research block must classify every model as one of these. ``n/a`` is the
#: honest answer for a non-model entry (a tactic, a library, a provenance
#: artifact) rather than forcing an open/closed label that does not apply.
ALLOWED_CLASSIFICATIONS = ("open", "closed", "n/a")

#: Required, non-empty research fields. Values adapt to the entity (an LLM fills
#: ``parameter_size``; a library may use ``"n/a"``) but every field is present.
REQUIRED_RESEARCH_FIELDS = (
    "classification",
    "publisher",
    "country",
    "parameter_size",
    "license",
    "canonical_url",
)

REQUIRED_PROVENANCE_FIELDS = (
    "assigned_by",
    # the model that did the naming, in provider_model form ("claude / opus") so
    # the frontend can show that model's own Pokémon ("named by model/Pokémon").
    "assigned_with",
    # the GitHub handle of the swarm contributor who ran the naming task.
    "contributor",
    "sources",
    "assigned_at",
)


def load_registry(path: str | Path) -> dict[str, Any]:
    """Load and JSON-decode a registry artifact."""
    return json.loads(Path(path).read_text(encoding="utf-8"))


def _is_nonempty_str(value: Any) -> bool:
    return isinstance(value, str) and value.strip() != ""


def _models(data: Any) -> list[dict[str, Any]]:
    if not isinstance(data, dict):
        return []
    models = data.get("models")
    return models if isinstance(models, list) else []


def assigned_models(data: dict[str, Any]) -> set[str]:
    """Provider/model strings already present in the registry."""
    return {
        m["provider_model"]
        for m in _models(data)
        if isinstance(m, dict) and _is_nonempty_str(m.get("provider_model"))
    }


def taken_dex_ids(data: dict[str, Any]) -> set[int]:
    """National-dex ids already assigned (so the next pick avoids them)."""
    ids: set[int] = set()
    for m in _models(data):
        if isinstance(m, dict) and isinstance(m.get("pokemon"), dict):
            dex_id = m["pokemon"].get("dex_id")
            if isinstance(dex_id, int):
                ids.add(dex_id)
    return ids


def taken_names(data: dict[str, Any]) -> set[str]:
    """Lower-cased Pokémon names already assigned (uniqueness is permanent)."""
    names: set[str] = set()
    for m in _models(data):
        if isinstance(m, dict) and isinstance(m.get("pokemon"), dict):
            name = m["pokemon"].get("name")
            if _is_nonempty_str(name):
                names.add(name.strip().lower())
    return names


def _validate_entry(
    entry: Any, index: int, manifest_path: Path | None
) -> list[str]:
    """Per-entry schema, completeness and Pokémon-validity checks."""
    out: list[str] = []
    if not isinstance(entry, dict):
        return [f"models[{index}]: entry must be an object"]

    pm = entry.get("provider_model")
    label = pm if _is_nonempty_str(pm) else f"models[{index}]"
    if not _is_nonempty_str(pm):
        out.append(f"models[{index}]: provider_model is required")

    # slug — derived deterministically from provider_model so the route and the
    # link always agree.
    slug = entry.get("slug")
    if not _is_nonempty_str(slug):
        out.append(f"{label}: slug is required")
    elif _is_nonempty_str(pm):
        expected = pokedex.slugify(pm)
        if slug != expected:
            out.append(
                f"{label}: slug '{slug}' must equal slugify(provider_model) "
                f"'{expected}'"
            )

    # pokemon
    poke = entry.get("pokemon")
    if not isinstance(poke, dict):
        out.append(f"{label}: pokemon block is required")
    else:
        name = poke.get("name")
        dex_id = poke.get("dex_id")
        if not _is_nonempty_str(name):
            out.append(f"{label}: pokemon.name is required")
        if not isinstance(dex_id, int):
            out.append(f"{label}: pokemon.dex_id must be an integer")
        if _is_nonempty_str(name) and isinstance(dex_id, int):
            if not pokedex.is_valid(dex_id, name, manifest_path):
                out.append(
                    f"{label}: pokemon {name}/{dex_id} is not a real Pokémon "
                    f"(name/dex_id mismatch or unknown)"
                )
            expected_sprite = pokedex.sprite_url(dex_id)
            if poke.get("sprite_url") != expected_sprite:
                out.append(
                    f"{label}: pokemon.sprite_url must be the front-default "
                    f"'{expected_sprite}'"
                )
        if not _is_nonempty_str(poke.get("description")):
            out.append(f"{label}: pokemon.description is required")

    # research
    research = entry.get("research")
    if not isinstance(research, dict):
        out.append(f"{label}: research block is required")
    else:
        for field in REQUIRED_RESEARCH_FIELDS:
            if not _is_nonempty_str(research.get(field)):
                out.append(f"{label}: research.{field} is required")
        classification = research.get("classification")
        if _is_nonempty_str(classification) and classification not in ALLOWED_CLASSIFICATIONS:
            out.append(
                f"{label}: research.classification '{classification}' must be "
                f"one of {'/'.join(ALLOWED_CLASSIFICATIONS)}"
            )
        url = research.get("canonical_url")
        if _is_nonempty_str(url) and not url.startswith(("http://", "https://")):
            out.append(f"{label}: research.canonical_url must be an http(s) URL")

    # profile (the rationale narrative)
    if not _is_nonempty_str(entry.get("profile")):
        out.append(f"{label}: profile is required")

    # provenance
    prov = entry.get("provenance")
    if not isinstance(prov, dict):
        out.append(f"{label}: provenance block is required")
    else:
        for field in REQUIRED_PROVENANCE_FIELDS:
            value = prov.get(field)
            if field == "sources":
                if not isinstance(value, list) or not value:
                    out.append(f"{label}: provenance.sources must be a non-empty list")
            elif not _is_nonempty_str(value):
                out.append(f"{label}: provenance.{field} is required")

    return out


def validate_registry(
    data: dict[str, Any], manifest_path: Path | None = None
) -> list[str]:
    """Return a list of human-readable violations (empty == valid)."""
    out: list[str] = []

    if not isinstance(data, dict):
        return ["registry root must be an object"]
    if not isinstance(data.get("schema_version"), int):
        out.append("schema_version must be an integer")
    if not _is_nonempty_str(data.get("generated_at")):
        out.append("generated_at is required (ISO-8601 UTC)")
    if not isinstance(data.get("models"), list):
        out.append("models must be a list")
        return out

    seen_models: set[str] = set()
    seen_slugs: set[str] = set()
    seen_ids: set[int] = set()
    seen_names: set[str] = set()

    for index, entry in enumerate(_models(data)):
        out.extend(_validate_entry(entry, index, manifest_path))
        if not isinstance(entry, dict):
            continue

        pm = entry.get("provider_model")
        if _is_nonempty_str(pm):
            if pm in seen_models:
                out.append(f"duplicate provider_model '{pm}'")
            seen_models.add(pm)

        slug = entry.get("slug")
        if _is_nonempty_str(slug):
            if slug in seen_slugs:
                out.append(f"duplicate slug '{slug}'")
            seen_slugs.add(slug)

        poke = entry.get("pokemon")
        if isinstance(poke, dict):
            dex_id = poke.get("dex_id")
            if isinstance(dex_id, int):
                if dex_id in seen_ids:
                    out.append(
                        f"duplicate pokemon dex_id {dex_id} — already assigned "
                        f"to another model"
                    )
                seen_ids.add(dex_id)
            name = poke.get("name")
            if _is_nonempty_str(name):
                key = name.strip().lower()
                if key in seen_names:
                    out.append(
                        f"duplicate pokemon name '{name}' — already assigned "
                        f"to another model"
                    )
                seen_names.add(key)

    return out


def distribution_models(path: str | Path) -> list[str]:
    """Read the provider/model labels from a leaderboard-ui.json artifact,
    preserving the published order (most proofs first)."""
    data = json.loads(Path(path).read_text(encoding="utf-8"))
    models = data.get("models") if isinstance(data, dict) else None
    if not isinstance(models, list):
        return []
    out: list[str] = []
    for m in models:
        if isinstance(m, dict) and _is_nonempty_str(m.get("provider_model")):
            out.append(m["provider_model"])
    return out


def unassigned(distribution: list[str], data: dict[str, Any]) -> list[str]:
    """Models present in the distribution but not yet in the registry,
    in distribution order (the work-list for the housekeeping task)."""
    have = assigned_models(data)
    seen: set[str] = set()
    out: list[str] = []
    for pm in distribution:
        if pm not in have and pm not in seen:
            out.append(pm)
            seen.add(pm)
    return out


def assemble_entry(
    provider_model: str,
    candidate: dict[str, Any],
    *,
    assigned_by: str,
    assigned_with: str,
    contributor: str,
    assigned_at: str,
    description_fn: Any = pokedex.fetch_flavor_text,
) -> dict[str, Any]:
    """Build a full registry entry from a model's research *candidate*.

    The candidate (produced by the swarm agent) supplies only the chosen
    ``pokemon`` (name + dex_id), the ``research`` block and the ``profile``
    rationale. The deterministic, authoritative fields — ``slug``,
    ``sprite_url`` and the Pokédex ``description`` — are computed here so a model
    can never hallucinate a sprite or a flavour text.
    """
    poke = candidate.get("pokemon") if isinstance(candidate.get("pokemon"), dict) else {}
    dex_id = poke.get("dex_id")
    research = candidate.get("research") if isinstance(candidate.get("research"), dict) else {}
    sources = candidate.get("sources")
    if not (isinstance(sources, list) and sources):
        canonical = research.get("canonical_url")
        sources = [canonical] if _is_nonempty_str(canonical) else []
    return {
        "provider_model": provider_model,
        "slug": pokedex.slugify(provider_model),
        "pokemon": {
            "name": poke.get("name"),
            "dex_id": dex_id,
            "sprite_url": pokedex.sprite_url(dex_id) if isinstance(dex_id, int) else "",
            "description": description_fn(dex_id) if isinstance(dex_id, int) else "",
        },
        "research": research,
        "profile": candidate.get("profile", ""),
        "provenance": {
            "assigned_by": assigned_by,
            "assigned_with": assigned_with,
            "contributor": contributor,
            "sources": sources,
            "assigned_at": assigned_at,
        },
    }


def add_entry(
    data: dict[str, Any], entry: dict[str, Any], manifest_path: Path | None = None
) -> tuple[dict[str, Any] | None, list[str]]:
    """Return ``(new_registry, [])`` if appending ``entry`` is a valid single
    addition, else ``(None, violations)``. Enforces the one-Pokémon-per-PR rule
    against the in-memory registry before anything is written."""
    head = {
        "schema_version": data.get("schema_version", 1),
        "generated_at": data.get("generated_at", ""),
        "models": [*_models(data), entry],
    }
    violations = check_single_addition(data, head, manifest_path)
    if violations:
        return None, violations
    return head, []


def _index_by_model(data: dict[str, Any]) -> dict[str, dict[str, Any]]:
    return {
        m["provider_model"]: m
        for m in _models(data)
        if isinstance(m, dict) and _is_nonempty_str(m.get("provider_model"))
    }


def check_single_addition(
    base: dict[str, Any], head: dict[str, Any], manifest_path: Path | None = None
) -> list[str]:
    """Enforce one-Pokémon-per-PR: head is valid, exactly one model added,
    nothing removed or modified relative to base.

    Exception — a deliberate **reset**: a PR that clears the registry to zero
    models is allowed (head must still be a valid, empty registry). This is the
    rare, obviously-destructive admin op used to hand naming back to the swarm;
    it is not bound by the append-only / one-add rule."""
    out: list[str] = list(validate_registry(head, manifest_path))

    if not _models(head):
        return out  # reset to empty — append-only/one-add rules do not apply

    base_by = _index_by_model(base)
    head_by = _index_by_model(head)

    removed = sorted(set(base_by) - set(head_by))
    for pm in removed:
        out.append(
            f"entry removed: '{pm}' — registry entries are append-only "
            f"(one-Pokémon-per-PR)"
        )

    for pm in sorted(set(base_by) & set(head_by)):
        if base_by[pm] != head_by[pm]:
            out.append(
                f"existing entry modified: '{pm}' — a PR may only add one new "
                f"model, not change existing ones"
            )

    added = sorted(set(head_by) - set(base_by))
    if len(added) != 1:
        out.append(
            f"a registry PR must add exactly one new model (added {len(added)}: "
            f"{', '.join(added) or 'none'})"
        )

    return out
