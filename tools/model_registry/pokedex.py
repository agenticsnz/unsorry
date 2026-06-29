"""Canonical Pokédex manifest and shared identity helpers (ADR-083).

The manifest (``pokedex.json``) is the *single source of truth* for which
Pokémon exist and what their national-dex id is. It is reused by:

- the housekeeping script, to enumerate available (unassigned) Pokémon;
- the registry validator, to reject names/ids that are not real Pokémon;
- the published artifact, whose ``sprite_url`` is built from the dex id.

Sprites are served from the PokéAPI ``sprites`` repository at a stable path —
the default *front* view, exactly as the feature requires. We store the dex id
in the manifest and derive the URL from one template so the convention lives in
a single place (DRY).
"""
from __future__ import annotations

import json
import re
import urllib.request
from functools import lru_cache
from pathlib import Path
from typing import Any

#: Sent on every PokéAPI request — the API's CDN rejects the default
#: ``Python-urllib`` agent with HTTP 403.
USER_AGENT = "unsorry-model-registry/1.0 (+https://github.com/agenticsnz/unsorry)"

#: Front-default sprite for national-dex ``<id>`` in the PokéAPI sprites repo.
#: Pinned to ``master`` — the repository's stable default branch.
SPRITE_URL_TEMPLATE = (
    "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/{id}.png"
)

#: PokéAPI species list — the canonical national-dex names (one per species).
SPECIES_LIST_URL = "https://pokeapi.co/api/v2/pokemon-species?limit=20000"

#: PokéAPI species detail — carries the English flavour text we store as the
#: Pokémon description.
SPECIES_DETAIL_URL = "https://pokeapi.co/api/v2/pokemon-species/{id}/"

MANIFEST_PATH = Path(__file__).with_name("pokedex.json")

#: A soft hyphen marks a hyphenated line-wrap (``out­\nperform``); drop it
#: *and* the whitespace that follows so the word rejoins (``outperform``).
_SOFT_HYPHEN_WRAP_RE = re.compile("­\\s*")
#: Remaining hard-wrap whitespace (form-feed and the newline/tab family) is
#: collapsed to single spaces.
_FLAVOR_WS_RE = re.compile(r"[\f\n\r\t ]+")


def http_get_json(url: str, timeout: int = 60) -> Any:
    """GET ``url`` and decode JSON, sending the required User-Agent."""
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return json.load(response)


def _clean_flavor(text: str) -> str:
    """Normalise PokéAPI flavour text into a single clean sentence string.

    Game flavour text is hard-wrapped with form-feeds, newlines and soft
    hyphens; rejoin soft-hyphen wraps, then collapse the whitespace family.
    """
    return _FLAVOR_WS_RE.sub(" ", _SOFT_HYPHEN_WRAP_RE.sub("", text)).strip()


def fetch_flavor_text(dex_id: int) -> str:
    """Return a cleaned English Pokédex flavour-text entry for ``dex_id``."""
    payload = http_get_json(SPECIES_DETAIL_URL.format(id=dex_id))
    for entry in payload.get("flavor_text_entries", []):
        if entry.get("language", {}).get("name") == "en":
            cleaned = _clean_flavor(entry.get("flavor_text", ""))
            if cleaned:
                return cleaned
    return ""


def sprite_url(dex_id: int) -> str:
    """Return the front-default sprite URL for a national-dex id."""
    return SPRITE_URL_TEMPLATE.format(id=dex_id)


def display_name(species_name: str) -> str:
    """Title-case a PokéAPI species slug for display.

    PokéAPI species names are lower-case hyphenated slugs (``mr-mime``,
    ``ho-oh``). We title-case each hyphen-separated part for a human label
    (``Mr-Mime``, ``Ho-Oh``); the manifest also keeps the raw slug.
    """
    return "-".join(part.capitalize() for part in species_name.split("-"))


_SLUG_STRIP_RE = re.compile(r"[^a-z0-9]+")


def slugify(value: str) -> str:
    """Lower-case, URL-safe slug used to key a model in the registry/route.

    ``"claude / opus"`` → ``"claude-opus"``. Collapses any run of
    non-alphanumeric characters to a single hyphen and trims the ends. The
    swarm computes this once at assignment and stores it so the frontend route
    (``/math/models/<slug>``) and the link agree (no encode/decode ambiguity).
    """
    return _SLUG_STRIP_RE.sub("-", value.strip().lower()).strip("-")


@lru_cache(maxsize=1)
def load_manifest(path: Path | None = None) -> dict[int, str]:
    """Load the vendored manifest as ``{dex_id: species_slug}``."""
    manifest_path = path or MANIFEST_PATH
    raw = json.loads(manifest_path.read_text(encoding="utf-8"))
    return {int(entry["id"]): entry["name"] for entry in raw["pokemon"]}


def is_valid(dex_id: int, name: str, path: Path | None = None) -> bool:
    """True iff ``(dex_id, name)`` matches a real Pokémon in the manifest.

    The comparison is case-insensitive on the display name and tolerant of the
    raw species slug, so both ``"Alakazam"`` and ``"alakazam"`` validate.
    """
    manifest = load_manifest(path)
    slug = manifest.get(dex_id)
    if slug is None:
        return False
    candidate = name.strip().lower()
    return candidate in {slug.lower(), display_name(slug).lower()}
