"""Generate the vendored Pokédex manifest from PokéAPI (ADR-083).

Run once (and whenever new generations are released) to refresh
``pokedex.json``:

    python3 -m tools.model_registry.build_pokedex

The manifest is the canonical national-dex name↔id mapping. We fetch the
*species* list (one entry per national-dex Pokémon, excluding alternate forms)
and keep only ``id`` and ``name`` — the minimum needed to validate assignments
and derive sprite URLs. Descriptions are fetched per-assignment by the
housekeeping task, not vendored here, so this file stays small and stable.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from .pokedex import MANIFEST_PATH, SPECIES_LIST_URL, http_get_json


def _species_id(url: str) -> int:
    """Extract the national-dex id from a species resource URL."""
    return int(url.rstrip("/").rsplit("/", 1)[-1])


def fetch_species() -> list[dict[str, int | str]]:
    """Fetch the national-dex species list, sorted by id."""
    payload = http_get_json(SPECIES_LIST_URL)
    pokemon = [
        {"id": _species_id(entry["url"]), "name": entry["name"]}
        for entry in payload["results"]
    ]
    pokemon.sort(key=lambda entry: entry["id"])
    return pokemon


def build(path: Path | None = None) -> int:
    """Write the manifest; return the number of Pokémon recorded."""
    pokemon = fetch_species()
    manifest = {
        "source": SPECIES_LIST_URL,
        "count": len(pokemon),
        "pokemon": pokemon,
    }
    target = path or MANIFEST_PATH
    target.write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    return len(pokemon)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="python3 -m tools.model_registry.build_pokedex",
        description="Refresh the vendored Pokédex manifest from PokéAPI.",
    )
    parser.add_argument(
        "--out", type=Path, default=None, help="output path (default: pokedex.json)"
    )
    args = parser.parse_args(argv)
    try:
        count = build(args.out)
    except OSError as error:
        print(f"error: {error}", file=sys.stderr)
        return 2
    print(f"wrote {count} Pokémon to {(args.out or MANIFEST_PATH)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
