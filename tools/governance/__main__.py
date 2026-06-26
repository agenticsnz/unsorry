"""CLI: validate the domain-admission registry and summarise it (SPEC-080-A).

    python3 -m tools.governance [registry-path]

Exit 0 if the registry parses and is well-formed; exit 2 on any error. A cheap
operator/CI check that the trust surface is structurally sound.
"""
from __future__ import annotations

import sys

from .admission import DEFAULT_REGISTRY_PATH, VERIFIED, RegistryError, load_registry


def main(argv: list[str] | None = None) -> int:
    args = sys.argv[1:] if argv is None else argv
    path = args[0] if args else str(DEFAULT_REGISTRY_PATH)
    try:
        registry = load_registry(path)
    except RegistryError as exc:
        print(f"registry invalid: {exc}", file=sys.stderr)
        return 2
    verified = [d.id for d in registry.domains if d.tier == VERIFIED]
    print(
        f"registry ok (schema v{registry.schema_version}): "
        f"{len(registry.domains)} domain(s), {len(registry.targets)} target(s)"
    )
    print(f"  VERIFIED domains: {', '.join(verified) or '(none)'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
