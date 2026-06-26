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
import os
import re
import shutil
import subprocess
import sys
import tempfile
from collections.abc import Callable, Iterator
from dataclasses import dataclass
from pathlib import Path

from tools.lean_sig import statement_sha
from tools.sourcing.gen_triples import render_lean, snake, valid_slug, write_triple

#: The unenforced sourcing batch cap — a 100-goal batch overran gate-a-prepare.
DEFAULT_BATCH = 50

#: ``theorem <name> <binders+type> := by|sorry`` — the signature is everything between
#: the name and the **proof** ``:=``. The ``:=`` must be followed by ``by``/``sorry`` so
#: an *internal* ``:=`` (e.g. ``let ⟨p, q⟩ := putnam_X_solution`` inside the statement)
#: does not truncate the signature (the putnam_1965_b4 bug).
_THEOREM_RE = re.compile(
    r"\btheorem\s+(?P<name>[A-Za-z_][A-Za-z0-9_'.]*)\b(?P<sig>.*?):=\s*(?:by\b|sorry\b)",
    re.DOTALL,
)


class ImportError_(Exception):
    """A benchmark statement could not be turned into a goal."""


#: Companion declarations a benchmark theorem references (e.g. PutnamBench's
#: ``abbrev putnam_X_solution : T := sorry``) precede the theorem. We bundle them into
#: the goal so the statement elaborates — substituting an answer-blank ``:= sorry`` with
#: the answer PutnamBench leaves in the adjacent ``-- <answer>`` comment, so the goal is
#: a *fixed, provable* statement rather than an opaque blank.
_BLOCK_COMMENT_RE = re.compile(r"/-.*?-/", re.DOTALL)
_LINE_COMMENT_RE = re.compile(r"--[^\n]*")
_ANSWER_RE = re.compile(r":=\s*sorry\s*\n\s*--\s*(?P<ans>[^\n]+)")


@dataclass(frozen=True)
class Problem:
    name: str          # the original theorem name, e.g. putnam_1988_b2
    signature: str     # binders + ": <type>" (everything between name and :=)
    source_ref: str
    preamble: str = ""  # companion declarations bundled before the theorem


def companion_preamble(text: str) -> str:
    """The companion declarations preceding the first theorem (imports/comments removed),
    with any answer-blank ``:= sorry`` substituted by the trailing ``-- <answer>`` comment.
    Empty for a pure-proof statement (no companions)."""
    match = re.search(r"\btheorem\b", text)
    head = text[: match.start()] if match else text
    head = _BLOCK_COMMENT_RE.sub("", head)                                # drop /- docstrings -/
    head = _ANSWER_RE.sub(lambda m: ":= " + m.group("ans").strip(), head)  # fold answer in
    head = _LINE_COMMENT_RE.sub("", head)                                 # drop remaining comments
    decls = [
        line.rstrip()
        for line in head.splitlines()
        if line.strip() and not line.lstrip().startswith("import")
    ]
    return "\n".join(decls).strip()


def slugify(name: str) -> str:
    """PutnamBench-style ``putnam_1988_b2`` → the kebab goal slug ``putnam-1988-b2``."""
    return name.replace("_", "-").replace(".", "-").lower()


def _subscript(i: int) -> str:
    return "".join(chr(0x2080 + int(d)) for d in str(i))


def extract_putnambench(
    text: str, source_ref: str = "", filename: str | None = None
) -> list[Problem]:
    """Extract every ``theorem`` statement plus its companion preamble from a Lean source
    file where the theorem name *is* the goal name (PutnamBench, miniF2F, CombiBench).
    ``filename`` is accepted for a uniform extractor signature but unused here."""
    preamble = companion_preamble(text)
    problems = []
    for match in _THEOREM_RE.finditer(text):
        # Preserve the original formatting verbatim — collapsing whitespace breaks
        # structurally-significant newlines (e.g. `let ⟨p, q⟩ := sol\n  body`, where a
        # space would re-parse `sol body` as application). The original PutnamBench
        # statement type-checks, so the only change we make is replacing its proof.
        sig = match.group("sig").strip()
        problems.append(
            Problem(
                name=match.group("name"),
                signature=sig,
                source_ref=source_ref,
                preamble=preamble,
            )
        )
    return problems


_NAMESPACE_RE = re.compile(r"^\s*(namespace|end)\b")


def extract_imolean(
    text: str, source_ref: str = "", filename: str | None = None
) -> list[Problem]:
    """IMOLean source: every file's theorem is named ``result`` inside a per-problem
    ``namespace`` (e.g. ``IMO2020P2``), so the goal name comes from the **filename**, and
    the namespace wrapper is dropped (the statement is self-contained over Mathlib)."""
    match = _THEOREM_RE.search(text)
    if match is None or not filename:
        return []
    preamble = "\n".join(
        line for line in companion_preamble(text).splitlines() if not _NAMESPACE_RE.match(line)
    ).strip()
    return [
        Problem(
            name=filename,
            signature=match.group("sig").strip(),
            source_ref=source_ref,
            preamble=preamble,
        )
    ]


#: Per-suite extractors (uniform ``(text, source_ref, filename) -> [Problem]`` signature).
EXTRACTORS: dict[str, Callable[[str, str, str | None], list[Problem]]] = {
    "theorem-named": extract_putnambench,  # PutnamBench / miniF2F / CombiBench
    "imolean": extract_imolean,            # filename-named, namespace-wrapped
}


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


def _segregate_benchmark_goal(root: Path, slug: str) -> None:
    """ADR-110: relocate a benchmark obligation's swarm-visible statement from
    ``goals/<slug>.lean`` to ``benchmark-goals/<slug>.lean`` so it is NOT globbed into
    the repo-pin ``UnsorryGoals`` build (``lakefile.toml`` globs ``goals.+``; the module
    ``benchmark_goals.<slug>`` is outside that). The obligation is elaborated and
    kernel-verified at its suite's pin in ``targets/<suite>/_verify`` (ADR-099), never at
    v4.30. The content-addressed package copy under ``targets/<suite>/goals/`` is the
    registry source of truth and is left untouched (its relative ``goals/<slug>.lean``
    artifact path resolves inside the package)."""
    dst = root / "benchmark-goals"
    dst.mkdir(exist_ok=True)
    for ext in ("lean", "aisp"):
        src = root / "goals" / f"{slug}.{ext}"
        text = src.read_text("utf-8")
        if ext == "aisp":
            text = text.replace(
                f"lean≜goals/{slug}.lean", f"lean≜benchmark-goals/{slug}.lean"
            )
        (dst / f"{slug}.{ext}").write_text(text, "utf-8")
        src.unlink()


def _existing_credit(pkg: Path) -> dict[str, str]:
    """The credit map from an existing suite skeleton, so re-importing into a suite
    **accumulates** obligations across batches instead of replacing them. Empty for a
    fresh suite."""
    skeleton = pkg / "skeleton.aisp"
    if not skeleton.is_file():
        return {}
    from tools.gate_b.records import parse_fields, parse_record

    record = parse_record(skeleton.read_text("utf-8"))
    block = record.block("Κ")
    return dict(parse_fields(block.body)) if block else {}


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

    # Accumulate across batches: keep prior obligations' credit, then add this batch.
    credit_by_slug = _existing_credit(pkg)
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
            preamble=problem.preamble,
        )
        # Content-addressed package copy (the registry copy; tied by statement_sha).
        for ext in ("lean", "aisp"):
            shutil.copyfile(root / "goals" / f"{slug}.{ext}", pkg_goals / f"{slug}.{ext}")
        # ADR-110: move the swarm-visible copy out of the v4.30 UnsorryGoals glob.
        _segregate_benchmark_goal(root, slug)
        credit_by_slug[slug] = credit_of(slug)

    # The skeleton lists EVERY obligation in the package (prior batches + this one), so a
    # suite > 50 accumulates into one target across PRs rather than each batch clobbering it.
    subs: list[tuple[str, str, str]] = [
        (
            slug,
            statement_sha((pkg_goals / f"{slug}.lean").read_text("utf-8")),
            credit_by_slug.get(slug, "credited"),
        )
        for slug in sorted(p.stem for p in pkg_goals.glob("*.lean") if p.stem != top)
    ]

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


def _probe_verdict(lean_text: str, root: Path, *, runner: Callable | None = None) -> str:
    """Full-battery probe verdict for one candidate statement — the ADR-078 ``glue`` vs
    ``credited`` classifier. ``trivial`` ⇒ the full battery closes it ⇒ glue; anything
    else ⇒ credited; ``probe-error`` ⇒ the statement did not even elaborate. Reuses
    ``tools.sourcing.check_triviality.probe``, which reads the .lean, builds a probe module
    in a tempdir, and runs ``lake env lean`` under ``root`` — so pointing ``root`` at the
    suite-scoped ``_verify`` project elaborates under the *suite* pin. ``runner`` is the
    injectable subprocess seam (tests pass a double; a real run uses ``subprocess.run``)."""
    from tools.intake.skeleton_validate import EXTRA_BATTERY
    from tools.sourcing.check_triviality import TACTIC_BATTERY, probe

    fd, name = tempfile.mkstemp(suffix=".lean")
    os.close(fd)
    path = Path(name)
    try:
        path.write_text(lean_text, encoding="utf-8")
        return probe(
            path, battery=TACTIC_BATTERY + EXTRA_BATTERY, root=root, runner=runner
        ).get("verdict", "probe-error")
    finally:
        path.unlink(missing_ok=True)


def _build_verdict(
    lean_text: str, vctx: Path, *, runner: Callable | None = None, timeout: float = 300.0
) -> str:
    """Real-build verdict: does the **actual statement** elaborate under the suite pin?

    Runs ``lake env lean`` on the statement itself (which ends in ``sorry`` — a *warning*,
    not an error, so no ``--wfail``) with ``cwd=vctx``. Returns ``build-ok`` (rc 0) or
    ``build-error``. This is stronger than the ``foralltype`` battery probe, which only
    elaborates the goal's *type*: it closes the probe-vs-build gap that passed 4
    non-building goals in #6371."""
    runner = runner or subprocess.run
    fd, name = tempfile.mkstemp(suffix=".lean")
    os.close(fd)
    path = Path(name)
    try:
        path.write_text(lean_text, encoding="utf-8")
        try:
            result = runner(
                ("lake", "env", "lean", str(path)),
                cwd=str(vctx), capture_output=True, text=True, timeout=timeout,
            )
        except subprocess.TimeoutExpired:
            return "build-error"
        return "build-ok" if result.returncode == 0 else "build-error"
    finally:
        path.unlink(missing_ok=True)


def build_verdict_of(vctx: Path, *, runner: Callable | None = None) -> Callable[[str], str]:
    """The ``verdict_of`` closure :func:`classify_problems` consumes, under the suite pin.

    The **real build** gates first (``build-error`` ⇒ quarantine); survivors go to the
    ``foralltype`` full-battery probe, which classifies ``trivial`` (glue) vs the rest
    (credited). Both run with ``root=vctx`` so everything is judged at the suite's pin."""
    def verdict_of(lean_text: str) -> str:
        if _build_verdict(lean_text, vctx, runner=runner) == "build-error":
            return "build-error"
        return _probe_verdict(lean_text, vctx, runner=runner)

    return verdict_of


#: A verdict that quarantines (statement reported, never imported) → its reason. The two
#: are distinguished so an operator can tell genuine pin drift (the real build fails) from
#: a probe/elaboration gap. ``build-error`` is emitted by :func:`build_verdict_of`.
_QUARANTINE_REASON = {
    "probe-error": "does not elaborate under the pinned mathlib",
    "build-error": "does not build under the suite pin",
}


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
        verdict = verdict_of(render_lean(slug, problem.signature, problem.preamble))
        reason = _QUARANTINE_REASON.get(verdict)
        if reason is not None:
            quarantined.append((problem.name, reason))
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
        "--extractor", default="theorem-named", choices=sorted(EXTRACTORS),
        help="per-suite extractor: theorem-named (PutnamBench/miniF2F/CombiBench) or imolean",
    )
    parser.add_argument(
        "--exclude", default="",
        help="comma-separated theorem/goal names to skip (e.g. a benchmark's errata list)",
    )
    parser.add_argument(
        "--build",
        action="store_true",
        help="elaborate each statement in a suite-scoped lake project at the suite's pin: "
        "quarantine the ones that don't build, and classify credited/glue via the ADR-078 "
        "full battery (needs Lean; requires --manifest)",
    )
    parser.add_argument(
        "--manifest",
        help="the suite's native lake-manifest.json (required with --build; ADR-099 "
        "decision A — operator-supplied, obtained via `lake update` at the native toolchain)",
    )
    parser.add_argument(
        "--no-warm-cache",
        action="store_true",
        help="skip `lake exe cache get` (offline re-run where _verify/.lake is populated)",
    )
    args = parser.parse_args(argv)

    extract = EXTRACTORS[args.extractor]
    excluded = {name.strip() for name in args.exclude.split(",") if name.strip()}
    src = Path(args.source)
    files = sorted(src.rglob("*.lean")) if src.is_dir() else [src]
    problems: list[Problem] = []
    for file in files:
        problems.extend(extract(file.read_text("utf-8"), args.reference, file.stem))
    if excluded:
        problems = [p for p in problems if p.name not in excluded]
    if not problems:
        print("no theorems found", file=sys.stderr)
        return 2

    # Idempotent batching: skip statements already imported, so a re-run picks up the
    # NEXT <=--limit obligations — a suite > 50 spans multiple PRs into one target.
    root_path = Path(args.root)
    extracted = len(problems)
    problems = [
        p for p in problems
        # already imported = present in either top-level dir: benchmark-goals/ for
        # native-pin obligations (ADR-110), or goals/ for suites first imported before
        # the segregation (so re-importing such a suite still dedups correctly).
        if not (
            (root_path / "benchmark-goals" / f"{slugify(p.name)}.lean").is_file()
            or (root_path / "goals" / f"{slugify(p.name)}.lean").is_file()
        )
    ]
    if not problems:
        print(f"all {extracted} extracted statement(s) already imported — nothing new",
              file=sys.stderr)
        return 0

    problems = problems[: args.limit]

    quarantined: list[tuple[str, str]] = []
    credit_map: dict[str, str] = {}
    if args.build:
        from tools.intake.verifier_context import (
            VerifierContextError,
            ensure_verifier_context,
        )
        from tools.sourcing.check_absence import manifest_rev

        if not args.manifest:
            print("--build requires --manifest (the suite's native lake-manifest.json)",
                  file=sys.stderr)
            return 2
        try:
            vctx = ensure_verifier_context(
                root_path, args.suite_id,
                toolchain=args.toolchain, mathlib=args.mathlib,
                manifest_src=Path(args.manifest),
                runner=subprocess.run, warm=not args.no_warm_cache,
            )
        except VerifierContextError as exc:
            print(f"verifier context error: {exc}", file=sys.stderr)
            return 2
        # Pin guard: the rev the suite is verified under MUST equal the rev recorded in
        # its metadata, so the .aisp pin can never diverge from the context that judged it.
        ctx_rev = manifest_rev(vctx)
        if ctx_rev != args.mathlib:
            print(f"pin mismatch: --mathlib {args.mathlib!r} != verifier-context rev "
                  f"{ctx_rev!r} (the --manifest records a different mathlib pin)",
                  file=sys.stderr)
            return 2
        problems, credit_map, quarantined = classify_problems(
            problems, verdict_of=build_verdict_of(vctx, runner=subprocess.run)
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
