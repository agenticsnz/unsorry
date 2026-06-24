"""Import a Lean benchmark suite as a registered skeleton package (ADR-081/092, M4).

Turns an external Lean benchmark suite (PutnamBench first) into:
- the swarm-visible obligations at top-level ``goals/<slug>.{aisp,lean}`` (+ ``backlog``),
  emitted via the existing :func:`tools.sourcing.gen_triples.write_triple` so they are
  ordinary open goals the swarm proves and Gate A/B re-verify; and
- a self-contained, ``skeleton-validate``-admissible package under
  ``targets/<suite>/`` (a synthetic ``<suite>-suite`` ``True`` sentinel root, the
  obligation copies, a flat ``top → obligation`` decomposition, and ``skeleton.aisp`` /
  ``target.aisp`` carrying the ADR-078 manifest + credited/glue classification).

The Lean-dependent steps — re-elaborating each statement under the pinned mathlib rev
(quarantine on failure) and the ADR-078 full-battery credited/glue probe — are an
**injectable seam** (``elaborate`` / ``credit_of``), stubbed hermetically in tests and
wired to ``tools.sourcing.check_triviality`` for a real run (which needs Lean). The
pure machinery here — extraction, slugging, package assembly, the ≤50 batch cap — is
fully tested without Lean.
"""
from __future__ import annotations

import argparse
import re
import shutil
import sys
from collections.abc import Callable, Iterator
from dataclasses import dataclass
from pathlib import Path

from tools.lean_sig import statement_sha
from tools.sourcing.gen_triples import render_lean, snake, valid_slug, write_triple

#: The unenforced sourcing batch cap — a 100-goal batch overran gate-a-prepare.
DEFAULT_BATCH = 50

#: ``theorem <name> <binders+type> := …`` — the signature is everything between the
#: name and the first ``:=`` (PutnamBench binders use ``:`` not ``:=``).
_THEOREM_RE = re.compile(
    r"\btheorem\s+(?P<name>[A-Za-z_][A-Za-z0-9_'.]*)\b(?P<sig>.*?):=", re.DOTALL
)


class ImportError_(Exception):
    """A benchmark statement could not be turned into a goal."""


@dataclass(frozen=True)
class Problem:
    name: str          # the original theorem name, e.g. putnam_1988_b2
    signature: str     # binders + ": <type>" (everything between name and :=)
    source_ref: str


def slugify(name: str) -> str:
    """PutnamBench-style ``putnam_1988_b2`` → the kebab goal slug ``putnam-1988-b2``."""
    return name.replace("_", "-").replace(".", "-").lower()


def _subscript(i: int) -> str:
    return "".join(chr(0x2080 + int(d)) for d in str(i))


def extract_putnambench(text: str, source_ref: str = "") -> list[Problem]:
    """Extract every ``theorem`` statement from PutnamBench Lean source."""
    problems = []
    for match in _THEOREM_RE.finditer(text):
        sig = re.sub(r"\s+", " ", match.group("sig")).strip()
        problems.append(Problem(name=match.group("name"), signature=sig, source_ref=source_ref))
    return problems


def batches(items: list, size: int = DEFAULT_BATCH) -> Iterator[list]:
    """Chunk ``items`` into ≤``size`` lists (the ≤50-obligation per-PR cap)."""
    if size <= 0:
        raise ValueError("batch size must be positive")
    for start in range(0, len(items), size):
        yield items[start : start + size]


def _open_goal_aisp(goal_id: str, difficulty: int, date: str) -> str:
    return (
        f"𝔸5.1.goal.{goal_id}@{date}\n"
        "γ≔unsorry.goal\n"
        f"⟦Ω:Goal⟧{{id≜{goal_id};phase≜prove;status≜open;difficulty≜{difficulty}}}\n"
        f"⟦Σ:Source⟧{{src≜backlog/{goal_id}.md}}\n"
        "⟦Γ:Deps⟧{deps≜⟨⟩}\n"
        f"⟦Λ:Artifact⟧{{lean≜goals/{goal_id}.lean;sha≜∅}}\n"
        "⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩\n"
    )


def assemble_package(
    root: Path,
    suite_id: str,
    problems: list[Problem],
    *,
    supplier: str,
    domain: str,            # the registry domain id, e.g. lean-math (→ target.aisp)
    mathlib: str,
    toolchain: str,
    license: str,
    shape: str = "math",    # the ADR-080 coarse shape for the manifest (skeleton-validate check 1)
    difficulty: int = 4,
    credit_of: Callable[[str], str] | None = None,
    date: str = "2026-06-24",
    force: bool = True,
) -> dict:
    """Emit the top-level obligation triples and the ``targets/<suite_id>/`` package.

    ``credit_of(slug) -> 'credited' | 'glue'`` defaults to ``credited`` (the real run
    passes the ADR-078 full-battery verdict). Returns a summary dict.
    """
    if len(problems) > DEFAULT_BATCH:
        raise ImportError_(
            f"{len(problems)} obligations exceeds the {DEFAULT_BATCH}-per-package cap; "
            "split with batches()"
        )
    credit_of = credit_of or (lambda _slug: "credited")
    root = Path(root)
    pkg = root / "targets" / suite_id
    pkg_goals = pkg / "goals"
    pkg_decomp = pkg / "decompositions"
    pkg_goals.mkdir(parents=True, exist_ok=True)
    pkg_decomp.mkdir(parents=True, exist_ok=True)

    top = f"{suite_id}-suite"
    sentinel = f"import Mathlib\n\ntheorem {snake(top)} : True := by\n  sorry\n"
    (pkg_goals / f"{top}.lean").write_text(sentinel, "utf-8")
    (pkg_goals / f"{top}.aisp").write_text(_open_goal_aisp(top, 0, date), "utf-8")

    subs: list[tuple[str, str, str]] = []  # (slug, statement_sha, credit)
    for problem in problems:
        slug = slugify(problem.name)
        if not valid_slug(slug):
            raise ImportError_(f"invalid slug {slug!r} from theorem {problem.name!r}")
        # Swarm-visible top-level triple (the queue copy the prover edits).
        write_triple(
            root,
            slug,
            lean_sig=problem.signature,
            statement=f"{suite_id} benchmark obligation {problem.name}",
            source=f"{suite_id} benchmark suite",
            reference=problem.source_ref,
            absence="imported benchmark statement (absent from the library)",
            triviality="classified credited/glue at registration (ADR-078 full battery)",
            difficulty=difficulty,
            decomposition="flat benchmark obligation under the suite root",
            date=date,
            force=force,
        )
        # Content-addressed package copy (the registry copy; tied by statement_sha).
        for ext in ("lean", "aisp"):
            shutil.copyfile(root / "goals" / f"{slug}.{ext}", pkg_goals / f"{slug}.{ext}")
        sha = statement_sha((root / "goals" / f"{slug}.lean").read_text("utf-8"))
        subs.append((slug, sha, credit_of(slug)))

    sub_lines = ";".join(
        f"sub{_subscript(i)}≜⟨id≜{slug},sha≜{sha}⟩"
        for i, (slug, sha, _) in enumerate(subs, 1)
    )
    edge_lines = ";".join(f"Post(sub{_subscript(i)})⊆Pre(parent)" for i in range(1, len(subs) + 1))
    credit_lines = ";".join(f"{slug}≜{credit}" for slug, _, credit in subs)

    (pkg_decomp / f"{top}.{supplier}.aisp").write_text(
        f"𝔸5.1.decomp.{top}.{supplier}@{date}\n"
        "γ≔unsorry.decomposition\n"
        f"⟦Ω:Decomp⟧{{parent≜{top};agent≜{supplier}}}\n"
        f"⟦Σ:Subs⟧{{{sub_lines}}}\n"
        f"⟦Γ:Edges⟧{{{edge_lines}}}\n"
        "⟦Λ:Requeue⟧{∀s∈subs:goal(s)≫status≔open}\n"
        "⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩\n",
        "utf-8",
    )
    (pkg / "skeleton.aisp").write_text(
        f"𝔸5.1.skeleton.{suite_id}@{date}\n"
        "γ≔unsorry.skeleton\n"
        f"⟦Μ:Manifest⟧{{top≜{top};supplier≜{supplier};domain≜{shape};"
        f"toolchain≜{toolchain};mathlib≜{mathlib}}}\n"
        f"⟦Σ:Subs⟧{{{sub_lines}}}\n"
        f"⟦Κ:Credit⟧{{{credit_lines}}}\n"
        "⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩\n",
        "utf-8",
    )
    (pkg / "target.aisp").write_text(
        f"𝔸5.1.target.{suite_id}@{date}\n"
        "γ≔unsorry.target\n"
        f"⟦Ω:Target⟧{{id≜{suite_id};supplier≜{supplier};domain≜{domain};"
        f"mathlib≜{mathlib};license≜{license};cohort≜benchmark;status≜open}}\n"
        "⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩\n",
        "utf-8",
    )

    return {
        "suite": suite_id,
        "top": top,
        "obligations": [slug for slug, _, _ in subs],
        "credited": sum(1 for _, _, c in subs if c != "glue"),
        "glue": sum(1 for _, _, c in subs if c == "glue"),
        "package": pkg.relative_to(root).as_posix(),
    }


def _probe_verdict(lean_text: str, root: Path) -> str:  # pragma: no cover - needs Lean
    """Full-battery probe verdict for one candidate statement (the real ``--build``
    classifier; needs Lean). ``probe-error`` ⇒ does not elaborate under the pin ⇒
    quarantine; ``trivial`` ⇒ the ADR-078 full battery closes it ⇒ glue; anything else
    ⇒ credited. Reuses ``tools.sourcing.check_triviality.probe``, which reads the .lean,
    builds a probe module in a tempdir, and runs ``lake env lean`` under ``root``."""
    import os
    import tempfile

    from tools.sourcing.check_triviality import TACTIC_BATTERY, probe

    fd, name = tempfile.mkstemp(suffix=".lean")
    os.close(fd)
    path = Path(name)
    try:
        path.write_text(lean_text, encoding="utf-8")
        return probe(path, battery=TACTIC_BATTERY + EXTRA_BATTERY, root=root).get(
            "verdict", "probe-error"
        )
    finally:
        path.unlink(missing_ok=True)


def classify_problems(
    problems: list[Problem], *, verdict_of: Callable[[str], str]
) -> tuple[list[Problem], dict[str, str], list[tuple[str, str]]]:
    """Partition extracted problems by their probe verdict — the ``--build`` step.

    Returns ``(kept, credit_by_slug, quarantined)``. ``verdict_of(lean_text)`` is the
    injectable seam: the real run wires it to :func:`_probe_verdict` (needs Lean);
    tests inject canned verdicts. A statement that does not elaborate under the pin is
    **quarantined** (reported, never imported); the rest are kept and tagged
    ``glue`` (full battery closes it) or ``credited``.
    """
    kept: list[Problem] = []
    credit: dict[str, str] = {}
    quarantined: list[tuple[str, str]] = []
    for problem in problems:
        slug = slugify(problem.name)
        verdict = verdict_of(render_lean(slug, problem.signature))
        if verdict == "probe-error":
            quarantined.append((problem.name, "does not elaborate under the pinned mathlib"))
        else:
            kept.append(problem)
            credit[slug] = "glue" if verdict == "trivial" else "credited"
    return kept, credit, quarantined


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="python3 -m tools.intake.import_benchmark",
        description="Import a Lean benchmark suite as a registered skeleton package.",
    )
    parser.add_argument("suite_id", help="the suite id, e.g. putnam-v1")
    parser.add_argument("source", help="a .lean file or directory of the benchmark suite")
    parser.add_argument("--supplier", required=True)
    parser.add_argument("--license", required=True)
    parser.add_argument("--domain", default="lean-math", help="registry domain id")
    parser.add_argument("--shape", default="math", choices=("math", "software", "construction"))
    parser.add_argument("--mathlib", required=True, help="the pinned mathlib rev")
    parser.add_argument("--toolchain", default="leanprover/lean4:v4.30.0")
    parser.add_argument("--difficulty", type=int, default=4)
    parser.add_argument("--reference", default="", help="suite source URL/citation")
    parser.add_argument("--root", default=".")
    parser.add_argument("--limit", type=int, default=DEFAULT_BATCH)
    parser.add_argument(
        "--build",
        action="store_true",
        help="elaborate each statement under the pinned mathlib: quarantine the ones "
        "that don't, and classify credited/glue via the ADR-078 full battery (needs Lean)",
    )
    args = parser.parse_args(argv)

    src = Path(args.source)
    files = sorted(src.rglob("*.lean")) if src.is_dir() else [src]
    problems: list[Problem] = []
    for file in files:
        problems.extend(extract_putnambench(file.read_text("utf-8"), args.reference))
    if not problems:
        print("no theorems found", file=sys.stderr)
        return 2

    problems = problems[: args.limit]

    quarantined: list[tuple[str, str]] = []
    credit_map: dict[str, str] = {}
    if args.build:
        problems, credit_map, quarantined = classify_problems(
            problems, verdict_of=lambda text: _probe_verdict(text, Path(args.root))
        )
        for name, reason in quarantined:
            print(f"  quarantined {name}: {reason}", file=sys.stderr)
        if not problems:
            print("all candidate statements were quarantined — nothing to import", file=sys.stderr)
            return 1

    summary = assemble_package(
        Path(args.root),
        args.suite_id,
        problems,
        supplier=args.supplier,
        domain=args.domain,
        mathlib=args.mathlib,
        toolchain=args.toolchain,
        license=args.license,
        shape=args.shape,
        difficulty=args.difficulty,
        credit_of=(lambda slug: credit_map.get(slug, "credited")) if credit_map else None,
    )
    print(
        f"imported {len(summary['obligations'])} obligation(s) into {summary['package']} "
        f"({summary['credited']} credited, {summary['glue']} glue, "
        f"{len(quarantined)} quarantined)"
    )
    if args.build and summary["credited"] == 0:
        print(
            "warning: no credited obligations — the full battery closes every leaf; "
            "skeleton-validate --build would reject this target (ADR-078)",
            file=sys.stderr,
        )

    # Self-validate: the assembled package must pass skeleton-validate (the suite must
    # already be registered in docs/governance/admitted-domains.json).
    from tools.governance.admission import RegistryError, load_registry
    from tools.intake.skeleton_validate import validate_package

    registry_path = Path(args.root) / "docs" / "governance" / "admitted-domains.json"
    try:
        registry = load_registry(registry_path)
    except RegistryError as exc:
        print(f"warning: skipping skeleton-validate ({exc})", file=sys.stderr)
        return 0
    result = validate_package(
        Path(args.root) / "targets" / args.suite_id, registry, strict=True
    )
    if not result.ok:
        print("skeleton-validate REJECTED the assembled package:", file=sys.stderr)
        for failure in result.failures:
            print(f"  {failure}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
