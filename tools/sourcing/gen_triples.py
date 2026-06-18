"""Goal-triple assembler (backlog sourcing, ADR-060 / SPEC-060-A).

A freshly *sourced* goal is three on-disk files (the "triple"), all for a goal
that is `status≜open` and unproved:

  * ``goals/<slug>.lean``  — `import Mathlib` + the theorem stated with `:= by sorry`
  * ``goals/<slug>.aisp``  — the SPEC-003-A goal record (open ⇒ ``sha≜∅``)
  * ``backlog/<slug>.md``  — the English statement + sourcing evidence bullets

Until now these were hand-authored, which is slow and easy to get subtly wrong
(the record is unicode-precise and Gate B is strict). This tool generates the
triple from one validated candidate and optionally re-runs Gate B over it, so a
contributor or agent produces a valid, immediately-checkable triple without
memorising the `.aisp` grammar. It is the assembler the ``unsorry-goal-sourcing``
skill invokes; it does no network and no git (the skill owns sync + dedup).

Scope: this tool *assembles* a triple that already passed the sourcing gates
(absence / non-triviality / provable-compile / skeptic — SPEC-060-A §1). It does
not re-run those gates; it records their verdicts into the backlog entry and
makes the result Gate-B-clean.

Usage:
  python3 -m tools.sourcing.gen_triples --slug <kebab-id> \\
      --lean-sig '<signature after the theorem name>' \\
      --statement '<one-line English statement>' --difficulty <0-5> \\
      --source '<...>' --reference '<...>' --absence '<...>' \\
      --triviality '<...>' --decomposition '<...>' \\
      [--aff -20] [--date YYYY-MM-DD] [--root .] [--validate] [--force]

  python3 -m tools.sourcing.gen_triples --from-candidate '<candidate block>' \\
      --difficulty 3 --source '<...>' ...   # parse slug+statement from a candidate line

Exit: 0 = triple written (and, with --validate, Gate-B-clean) · 1 = validation
failed · 2 = usage error.
"""
from __future__ import annotations

import argparse
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

#: A goal id is kebab-case, no dots (records.py ID_PATTERN; SPEC-003-A §9).
_SLUG_RE = re.compile(r"^[a-z0-9][a-z0-9-]*$")
#: Pull `` `snake_name` — statement `` out of a candidate checklist line (the
#: statement runs to the end of that line; the candidate's evidence is on line 2).
_CANDIDATE_RE = re.compile(r"`(?P<name>[a-z0-9_]+)`\s*—\s*(?P<statement>[^\n]+)")


def snake(slug: str) -> str:
    """Lean theorem name for a goal slug: kebab → snake (the repo convention,
    e.g. ``alternating-sum-...`` → ``alternating_sum_...``)."""
    return slug.replace("-", "_")


def valid_slug(slug: str) -> bool:
    return bool(_SLUG_RE.match(slug)) and "." not in slug


def render_lean(slug: str, sig: str) -> str:
    """The canonical sorry-stub: `import Mathlib`, a blank line, the theorem, and
    a two-space `sorry`. `sig` is everything after the theorem name (binders +
    `:` + proposition), e.g. ``(n : ℕ) : 0 < n + 1``."""
    return f"import Mathlib\n\ntheorem {snake(slug)} {sig.strip()} := by\n  sorry\n"


def render_aisp(slug: str, difficulty: int, date: str, aff: int) -> str:
    """The SPEC-003-A goal record for a *fresh* (open, unproved) goal. Open ⇒
    ``sha≜∅``; ``phase≜prove``; the evidence band is the fixed sourced-goal
    seed ``⟨δ≜0.60;τ≜◊⁺⟩``."""
    return (
        f"𝔸5.1.goal.{slug}@{date}\n"
        "γ≔unsorry.goal\n"
        "⟦Ω:Goal⟧{\n"
        f"  id≜{slug}\n"
        "  phase≜prove\n"
        "  status≜open\n"
        f"  difficulty≜{difficulty}\n"
        "}\n"
        "⟦Σ:Source⟧{\n"
        f"  src≜backlog/{slug}.md\n"
        "}\n"
        "⟦Γ:Deps⟧{\n"
        "  deps≜⟨⟩\n"
        "}\n"
        "⟦Λ:Artifact⟧{\n"
        f"  lean≜goals/{slug}.lean\n"
        "  sha≜∅\n"
        f"  aff≜{aff}\n"
        "}\n"
        "⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩\n"
    )


def render_backlog(
    slug: str,
    *,
    statement: str,
    source: str,
    reference: str,
    absence: str,
    triviality: str,
    difficulty: int,
    decomposition: str,
) -> str:
    """The human backlog entry: title, the statement, then the six evidence
    bullets (SPEC-043-A). Gate B checks that this file *exists* (GB008); it does
    not validate its structure, but the skill relies on the six bullets."""
    return (
        f"# {slug}\n\n"
        f"{statement.strip()}\n\n"
        f"- **Source:** {source.strip()}\n"
        f"- **Reference:** {reference.strip()}\n"
        f"- **Absence:** {absence.strip()}\n"
        f"- **Triviality:** {triviality.strip()}\n"
        f"- **Difficulty:** {difficulty}\n"
        f"- **Decomposition sketch:** {decomposition.strip()}\n"
    )


class TripleError(Exception):
    """A usage/precondition error (bad slug, would-clobber, bad difficulty)."""


def write_triple(
    root: Path,
    slug: str,
    *,
    lean_sig: str,
    statement: str,
    source: str,
    reference: str,
    absence: str,
    triviality: str,
    difficulty: int,
    decomposition: str,
    aff: int = -20,
    date: str | None = None,
    force: bool = False,
) -> list[Path]:
    """Write the three files; return their paths. Refuses to clobber an existing
    goal unless ``force`` (ADR-018 immutability — a changed statement gets a new
    slug, never an in-place edit)."""
    if not valid_slug(slug):
        raise TripleError(
            f"invalid slug {slug!r}: must match [a-z0-9][a-z0-9-]* with no dots"
        )
    if not 0 <= difficulty <= 5:
        raise TripleError(f"difficulty {difficulty} out of range 0–5")
    date = date or datetime.now(timezone.utc).strftime("%Y-%m-%d")
    if not re.match(r"^\d{4}-\d{2}-\d{2}$", date):
        raise TripleError(f"date {date!r} is not YYYY-MM-DD")

    lean_path = root / "goals" / f"{slug}.lean"
    aisp_path = root / "goals" / f"{slug}.aisp"
    backlog_path = root / "backlog" / f"{slug}.md"
    if not force:
        for p in (lean_path, aisp_path, backlog_path):
            if p.exists():
                raise TripleError(
                    f"{p} already exists (use --force, or pick a new slug — "
                    "goal statements are create-only, ADR-018)"
                )

    lean_path.parent.mkdir(parents=True, exist_ok=True)
    backlog_path.parent.mkdir(parents=True, exist_ok=True)
    lean_path.write_text(render_lean(slug, lean_sig), encoding="utf-8")
    aisp_path.write_text(render_aisp(slug, difficulty, date, aff), encoding="utf-8")
    backlog_path.write_text(
        render_backlog(
            slug,
            statement=statement,
            source=source,
            reference=reference,
            absence=absence,
            triviality=triviality,
            difficulty=difficulty,
            decomposition=decomposition,
        ),
        encoding="utf-8",
    )
    return [lean_path, aisp_path, backlog_path]


def parse_candidate(block: str) -> tuple[str, str]:
    """(slug, statement) from a candidate checklist line. The candidate carries a
    snake_case Lean name in backticks; the goal slug is its kebab form."""
    m = _CANDIDATE_RE.search(block)
    if not m:
        raise TripleError(
            "could not parse a candidate line (expected `` `snake_name` — statement ``)"
        )
    return m.group("name").replace("_", "-"), m.group("statement")


def _build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="python3 -m tools.sourcing.gen_triples")
    p.add_argument("--slug", help="goal id (kebab-case, no dots)")
    p.add_argument("--from-candidate", help="parse slug+statement from a candidate line")
    p.add_argument("--lean-sig", help="Lean signature after the theorem name")
    p.add_argument("--statement", help="one-line English statement")
    p.add_argument("--difficulty", type=int, required=True)
    p.add_argument("--source", default="")
    p.add_argument("--reference", default="")
    p.add_argument("--absence", default="")
    p.add_argument("--triviality", default="")
    p.add_argument("--decomposition", default="")
    p.add_argument("--aff", type=int, default=-20)
    p.add_argument("--date")
    p.add_argument("--root", default=".")
    p.add_argument("--validate", action="store_true", help="run Gate B over the written tree")
    p.add_argument("--force", action="store_true")
    return p


def main(argv: list[str] | None = None) -> int:
    args = _build_parser().parse_args(argv)
    slug, statement = args.slug, args.statement
    try:
        if args.from_candidate:
            parsed_slug, parsed_statement = parse_candidate(args.from_candidate)
            slug = slug or parsed_slug
            statement = statement or parsed_statement
        if not slug:
            raise TripleError("need --slug or --from-candidate")
        if not args.lean_sig:
            raise TripleError("need --lean-sig (the signature after the theorem name)")
        if not statement:
            raise TripleError("need --statement (or a parseable --from-candidate)")
        paths = write_triple(
            Path(args.root),
            slug,
            lean_sig=args.lean_sig,
            statement=statement,
            source=args.source,
            reference=args.reference,
            absence=args.absence,
            triviality=args.triviality,
            difficulty=args.difficulty,
            decomposition=args.decomposition,
            aff=args.aff,
            date=args.date,
            force=args.force,
        )
    except TripleError as exc:
        print(f"gen_triples: {exc}", file=sys.stderr)
        return 2

    for path in paths:
        print(path)

    if args.validate:
        from tools.gate_b.validator import render_human, validate_tree

        violations = validate_tree(Path(args.root))
        if violations:
            print(render_human(violations), file=sys.stderr)
            return 1
        print("Gate B: clean", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
