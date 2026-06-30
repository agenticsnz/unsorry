"""Model registry CLI — the CI gate (ADR-083).

Exit codes: 0 clean, 1 violations found, 2 internal/usage error.

    python3 -m tools.model_registry validate docs/metrics/model-registry.json
    python3 -m tools.model_registry check-added --base BASE.json --head HEAD.json
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from . import registry


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="python3 -m tools.model_registry",
        description="Validate the model → Pokémon registry (ADR-083).",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    validate = sub.add_parser("validate", help="validate a registry artifact")
    validate.add_argument("path", help="path to model-registry.json")

    added = sub.add_parser(
        "check-added",
        help="enforce one-Pokémon-per-PR (head valid; exactly one model added)",
    )
    added.add_argument("--base", required=True, help="registry on the base branch")
    added.add_argument("--head", required=True, help="registry on the PR head")

    unassigned = sub.add_parser(
        "unassigned",
        help="print models in the distribution not yet in the registry",
    )
    unassigned.add_argument("--distribution", required=True, help="leaderboard-ui.json")
    unassigned.add_argument("--registry", required=True, help="model-registry.json")

    add = sub.add_parser(
        "add-entry",
        help="validate a single new entry and write it into the registry",
    )
    add.add_argument("--registry", required=True, help="model-registry.json (updated in place)")
    add.add_argument("--entry", required=True, help="JSON file with the new entry")

    assign = sub.add_parser(
        "assign",
        help="assemble an entry from a research candidate, validate and write it",
    )
    assign.add_argument("--registry", required=True, help="model-registry.json (updated in place)")
    assign.add_argument("--provider-model", required=True, help="the model being named")
    assign.add_argument("--candidate", required=True, help="JSON: pokemon/research/profile")
    assign.add_argument("--assigned-by", required=True, help="agent id")
    assign.add_argument(
        "--assigned-with", required=True,
        help="naming model in provider_model form, e.g. 'claude / opus'",
    )
    assign.add_argument(
        "--contributor", required=True, help="owning swarm contributor (GitHub handle)"
    )
    assign.add_argument("--assigned-at", required=True, help="ISO-8601 UTC timestamp")

    return parser


def _report(violations: list[str]) -> int:
    if not violations:
        print("model-registry: OK")
        return 0
    print(f"model-registry: {len(violations)} violation(s):", file=sys.stderr)
    for violation in violations:
        print(f"  - {violation}", file=sys.stderr)
    return 1


def main(argv: list[str] | None = None) -> int:
    args = _build_parser().parse_args(argv)
    try:
        if args.command == "validate":
            violations = registry.validate_registry(registry.load_registry(args.path))
        elif args.command == "check-added":
            violations = registry.check_single_addition(
                registry.load_registry(args.base),
                registry.load_registry(args.head),
            )
        elif args.command == "unassigned":
            todo = registry.unassigned(
                registry.distribution_models(args.distribution),
                registry.load_registry(args.registry),
            )
            print("\n".join(todo))
            return 0
        elif args.command in ("add-entry", "assign"):
            data = registry.load_registry(args.registry)
            if args.command == "assign":
                candidate = json.loads(Path(args.candidate).read_text(encoding="utf-8"))
                entry = registry.assemble_entry(
                    args.provider_model,
                    candidate,
                    assigned_by=args.assigned_by,
                    assigned_with=args.assigned_with,
                    contributor=args.contributor,
                    assigned_at=args.assigned_at,
                )
            else:
                entry = json.loads(Path(args.entry).read_text(encoding="utf-8"))
            new_data, violations = registry.add_entry(data, entry)
            if new_data is not None:
                Path(args.registry).write_text(
                    json.dumps(new_data, indent=2, ensure_ascii=False) + "\n",
                    encoding="utf-8",
                )
        else:  # pragma: no cover - argparse enforces a valid subcommand
            raise ValueError(f"unknown command {args.command!r}")
    except FileNotFoundError as error:
        print(f"error: {error}", file=sys.stderr)
        return 2
    except (OSError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 2
    return _report(violations)


if __name__ == "__main__":
    sys.exit(main())
