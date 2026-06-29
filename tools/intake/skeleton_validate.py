"""skeleton-validate — the curated-package intake validator (ADR-081 / SPEC-081-A).

A deterministic, stdlib-only validator that decides whether a submitted **curated
skeleton package** is well-formed enough to admit into the queue. A package passes
wholly (every leaf obligation becomes a queued goal) or is rejected wholly (never
partially queued). It checks *structure*, not mathematical correctness — that stays
the kernel's job at Gate A.

A skeleton package is a directory carrying, relative to the package root:

- ``skeleton.aisp`` — the manifest. An AISP record whose fields give ``top≜<goal-id>``
  (the root statement), ``supplier≜<vetted-id>``, ``domain≜math|software|construction``,
  and the pinned verifier context ``toolchain≜…; mathlib≜…``.
- ``goals/<id>.aisp`` + ``goals/<id>.lean`` for every obligation (the root and each
  sub) — standard open-goal records (``status≜open``, ``⟦Λ:Artifact⟧{lean≜…; sha≜∅}``)
  whose ``.lean`` ends in ``sorry``.
- ``decompositions/<parent>.<supplier>.aisp`` — one decomposition record per internal
  node, declaring its subs (content-addressed) and the ADR-009 dependency edges.

Checks (each a pure predicate; all must pass — SPEC-081-A §41-72):

1. Manifest well-formed.
2. Curated-target provenance (vetted supplier, admitted domain).
3. Every obligation is a well-formed open goal.
4. Decomposition edges sound, acyclic, rooted at ``top``, no orphans.
5. No degenerate pass-through padding (advisory; ``--strict`` makes it fatal).
6. ``--build``: verifier context resolves and the top statement type-checks.
7. ``--build``: credited-vs-glue — a target needs ≥1 credited (full-battery-surviving)
   obligation (ADR-078).

CLI / exit codes mirror Gate B: **0** admit · **1** rejected · **2** internal/usage.
"""
from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass, field
from pathlib import Path

from tools.gate_b.graph import EDGE_RE, SUB_RE, has_cycle
from tools.gate_b.records import EMPTY, is_id, is_sha256, parse_record
from tools.governance.admission import (
    Registry,
    RegistryError,
    domain_admissible,
    load_registry,
    target_curated,
)
from tools.lean_sig import statement, statement_sha, theorem_name

#: The coarse admissible shapes a manifest may declare (ADR-080 / SPEC-081-A).
MANIFEST_DOMAINS = ("math", "software", "construction")

#: ADR-078 registration-time full battery: the ADR-035 sourcing set together with
#: the four tactics it excludes, so a node closable by any of them is *glue*.
EXTRA_BATTERY = ("nlinarith", "positivity", "field_simp", "gcongr")

EXIT_ADMIT, EXIT_REJECT, EXIT_ERROR = 0, 1, 2


@dataclass
class Result:
    """Outcome of validating one package. ``ok`` ⇒ admit (exit 0)."""

    package: str
    failures: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)
    leaves: list[str] = field(default_factory=list)
    credited: list[str] = field(default_factory=list)
    glue: list[str] = field(default_factory=list)
    error: str | None = None  # internal/usage error ⇒ exit 2

    def fail(self, check: str, message: str) -> None:
        self.failures.append(f"[{check}] {message}")

    def warn(self, check: str, message: str) -> None:
        self.warnings.append(f"[{check}] {message}")

    @property
    def ok(self) -> bool:
        return self.error is None and not self.failures

    @property
    def exit_code(self) -> int:
        if self.error is not None:
            return EXIT_ERROR
        return EXIT_ADMIT if not self.failures else EXIT_REJECT


def _read(path: Path) -> str | None:
    try:
        return path.read_text(encoding="utf-8")
    except (FileNotFoundError, UnicodeDecodeError):
        return None


def _ends_in_sorry(lean_text: str) -> bool:
    """The proof body is an unmet obligation: the statement ends in ``sorry``."""
    return lean_text.rstrip().endswith("sorry")


def _proposition(lean_text: str) -> str | None:
    """The statement with its declared name blanked out — so two goals with the
    same proposition but different theorem names compare equal (pass-through
    detection must ignore the name, which ``statement_sha`` deliberately addresses)."""
    try:
        return statement(lean_text).replace(theorem_name(lean_text), "_", 1)
    except ValueError:
        return None


def _safe_statement_sha(lean_text: str) -> str | None:
    """``statement_sha`` but ``None`` for a malformed .lean (no theorem/``:=``)."""
    try:
        return statement_sha(lean_text)
    except ValueError:
        return None


# --------------------------------------------------------------- 1. manifest


def _check_manifest(pkg: Path, goals: set[str], result: Result) -> dict[str, str]:
    text = _read(pkg / "skeleton.aisp")
    if text is None:
        result.fail("1-manifest", "skeleton.aisp is missing or not valid UTF-8")
        return {}
    fields = parse_record(text).fields
    for key in ("top", "supplier", "domain", "toolchain", "mathlib"):
        if not fields.get(key):
            result.fail("1-manifest", f"manifest field '{key}' is missing or empty")
    domain = fields.get("domain", "")
    if domain and domain not in MANIFEST_DOMAINS:
        result.fail(
            "1-manifest",
            f"domain '{domain}' is not one of {'/'.join(MANIFEST_DOMAINS)}",
        )
    top = fields.get("top", "")
    if top and top not in goals:
        result.fail("1-manifest", f"top '{top}' has no goals/{top}.aisp record")
    return fields


# ----------------------------------------------------------- 2. provenance


def _check_provenance(pkg: Path, manifest: dict[str, str], registry: Registry, result: Result) -> None:
    package_id = pkg.name
    supplier = target_curated(package_id, registry)
    if supplier is None:
        result.fail(
            "2-provenance",
            f"package '{package_id}' is not a registered curated target "
            "(self-minted packages are rejected)",
        )
        return
    if not domain_admissible(supplier.domain, registry):
        result.fail(
            "2-provenance",
            f"package domain '{supplier.domain}' is not admitted at tier VERIFIED",
        )
    declared = manifest.get("supplier")
    if declared and declared != supplier.supplier:
        result.fail(
            "2-provenance",
            f"manifest supplier '{declared}' does not match the registry "
            f"supplier '{supplier.supplier}'",
        )


# ------------------------------------------------------------- 3. obligations


def _check_obligations(pkg: Path, goals: set[str], result: Result) -> None:
    for goal_id in sorted(goals):
        aisp_text = _read(pkg / "goals" / f"{goal_id}.aisp")
        if aisp_text is None:
            result.fail("3-obligation", f"'{goal_id}' .aisp is missing or not UTF-8")
            continue
        fields = parse_record(aisp_text).fields
        if not is_id(goal_id):
            result.fail("3-obligation", f"'{goal_id}' violates the Id grammar")
        if fields.get("status") != "open":
            result.fail("3-obligation", f"'{goal_id}' is not status≜open")
        if fields.get("phase") != "prove":
            result.fail("3-obligation", f"'{goal_id}' is not phase≜prove")
        if fields.get("sha") != EMPTY:
            result.fail("3-obligation", f"'{goal_id}' must carry sha≜{EMPTY} (open)")
        lean_text = _read(pkg / "goals" / f"{goal_id}.lean")
        if lean_text is None:
            result.fail("3-obligation", f"'{goal_id}' has no goals/{goal_id}.lean")
        elif not _ends_in_sorry(lean_text):
            result.fail("3-obligation", f"'{goal_id}' .lean does not end in sorry")


# --------------------------------------------------------------- 4. edges


@dataclass
class _Decomp:
    parent: str
    subs: list[tuple[str, str, str]]  # (label, id, sha)
    edges: list[tuple[str, str]]      # (src-label, dst-label)


def _parse_decomps(pkg: Path, result: Result) -> list[_Decomp]:
    decomps: list[_Decomp] = []
    directory = pkg / "decompositions"
    if not directory.is_dir():
        return decomps
    for path in sorted(directory.glob("*.aisp")):
        text = _read(path)
        if text is None:
            result.fail("4-edges", f"{path.name} is missing or not UTF-8")
            continue
        record = parse_record(text)
        parent = record.fields.get("parent", "")
        subs_block = record.block("Σ")
        edges_block = record.block("Γ")
        subs = [
            (m.group("label"), m.group("id"), m.group("sha"))
            for m in SUB_RE.finditer(subs_block.body if subs_block else "")
        ]
        edges = [
            (m.group("src").strip(), m.group("dst").strip())
            for m in EDGE_RE.finditer(edges_block.body if edges_block else "")
        ]
        if not parent:
            result.fail("4-edges", f"{path.name} has no parent")
        decomps.append(_Decomp(parent=parent, subs=subs, edges=edges))
    return decomps


def _check_edges(pkg: Path, top: str, goals: set[str], decomps: list[_Decomp], result: Result) -> None:
    child_edges: list[tuple[str, str]] = []  # parent-id → sub-id (the decomposition tree)
    children_with_parent: set[str] = set()

    for decomp in decomps:
        if decomp.parent and decomp.parent not in goals:
            result.fail("4-edges", f"parent '{decomp.parent}' is not a package goal")
        labels = {"parent"}
        for label, sub_id, sub_sha in decomp.subs:
            labels.add(label)
            if not is_id(sub_id):
                result.fail("4-edges", f"sub id '{sub_id}' violates the Id grammar")
            elif sub_id not in goals:
                result.fail("4-edges", f"sub '{sub_id}' has no package goal")
            elif sub_id == decomp.parent:
                result.fail("4-edges", f"sub '{sub_id}' re-emits its parent")
            else:
                child_edges.append((decomp.parent, sub_id))
                children_with_parent.add(sub_id)
            if not is_sha256(sub_sha):
                result.fail("4-edges", f"sub '{sub_id}' sha is not a SHA-256 address")
            else:
                lean_text = _read(pkg / "goals" / f"{sub_id}.lean")
                actual = _safe_statement_sha(lean_text) if lean_text is not None else None
                if actual is not None and actual != sub_sha:
                    result.fail(
                        "4-edges",
                        f"sub '{sub_id}' sha does not match goals/{sub_id}.lean",
                    )
        for src, dst in decomp.edges:
            for endpoint in (src, dst):
                if endpoint not in labels:
                    result.fail(
                        "4-edges",
                        f"edge endpoint '{endpoint}' is neither 'parent' nor a "
                        f"declared sub of '{decomp.parent}'",
                    )
        if has_cycle(decomp.edges):
            result.fail("4-edges", f"decomposition of '{decomp.parent}' has a cycle")

    if has_cycle(child_edges):
        result.fail("4-edges", "the decomposition tree (parent→sub) has a cycle")

    # Rooted at top + no orphans: every non-top goal must be reachable from top
    # via parent→sub edges, and must have a parent.
    if top:
        adjacency: dict[str, list[str]] = {}
        for parent_id, sub_id in child_edges:
            adjacency.setdefault(parent_id, []).append(sub_id)
        reachable: set[str] = set()
        stack = [top]
        while stack:
            node = stack.pop()
            if node in reachable:
                continue
            reachable.add(node)
            stack.extend(adjacency.get(node, []))
        for goal_id in sorted(goals):
            if goal_id == top:
                continue
            if goal_id not in children_with_parent:
                result.fail("4-edges", f"orphan goal '{goal_id}' (no parent)")
            elif goal_id not in reachable:
                result.fail("4-edges", f"goal '{goal_id}' is not reachable from top")


# ----------------------------------------------------------- 5. no padding


def _check_padding(pkg: Path, decomps: list[_Decomp], strict: bool, result: Result) -> None:
    for decomp in decomps:
        if len(decomp.subs) != 1:
            continue
        _, sub_id, _ = decomp.subs[0]
        parent_lean = _read(pkg / "goals" / f"{decomp.parent}.lean")
        sub_lean = _read(pkg / "goals" / f"{sub_id}.lean")
        if parent_lean is None or sub_lean is None:
            continue
        parent_prop = _proposition(parent_lean)
        sub_prop = _proposition(sub_lean)
        if parent_prop is not None and parent_prop == sub_prop:
            message = (
                f"pass-through: '{decomp.parent}' has one sub '{sub_id}' with an "
                "identical statement"
            )
            (result.fail if strict else result.warn)("5-padding", message)


# --------------------------------------------------------- 6/7. build checks


def _check_build(pkg: Path, top: str, goals: set[str], result: Result) -> None:
    """Checks 6 (top type-checks) and 7 (≥1 credited obligation). Invokes Lean."""
    try:
        from tools.sourcing.check_triviality import TACTIC_BATTERY, probe
    except Exception as exc:  # pragma: no cover - environment-dependent
        result.error = f"--build requires the triviality probe: {exc}"
        return
    battery = TACTIC_BATTERY + EXTRA_BATTERY

    # Elaborate under the suite-scoped verifier context (ADR-099 / SPEC-099-A §1) when it
    # has been prepared: its lake project pins the suite's *native* mathlib, so a suite
    # authored against an older mathlib is judged at its own pin instead of the repo's.
    # Fall back to the package dir (which resolves to the repo pin) only when no context
    # is present — correct just for repo-pinned suites.
    vctx = pkg / "_verify"
    probe_root = vctx if (vctx / "lakefile.toml").is_file() else pkg

    leaves = [g for g in sorted(goals) if g != top]
    for goal_id in [top, *leaves]:
        lean = pkg / "goals" / f"{goal_id}.lean"
        verdict = probe(lean, battery=battery, root=probe_root).get("verdict")
        if verdict == "probe-error":
            if goal_id == top:
                result.fail("6-build", f"top '{top}' statement does not elaborate")
            else:
                result.fail("6-build", f"'{goal_id}' statement does not elaborate")
        elif goal_id != top:
            (result.glue if verdict == "trivial" else result.credited).append(goal_id)

    if leaves and not result.credited:
        result.fail(
            "7-credit",
            "no credited obligations — every leaf is closed by the full battery (glue)",
        )


# ------------------------------------------------------------- orchestration


def validate_package(
    package_dir: Path,
    registry: Registry,
    *,
    strict: bool = False,
    build: bool = False,
) -> Result:
    pkg = Path(package_dir)
    result = Result(package=pkg.name)
    if not pkg.is_dir():
        result.error = f"package directory not found: {pkg}"
        return result

    goals = {p.stem for p in (pkg / "goals").glob("*.aisp")} if (pkg / "goals").is_dir() else set()
    if not goals:
        result.fail("3-obligation", "package declares no goals/")

    manifest = _check_manifest(pkg, goals, result)
    _check_provenance(pkg, manifest, registry, result)
    _check_obligations(pkg, goals, result)
    decomps = _parse_decomps(pkg, result)
    top = manifest.get("top", "")
    _check_edges(pkg, top, goals, decomps, result)
    _check_padding(pkg, decomps, strict, result)

    result.leaves = sorted(g for g in goals if g != top)
    if build and result.ok:
        _check_build(pkg, top, goals, result)
    return result


# --------------------------------------------------------------------- CLI


def _render(result: Result, as_json: bool) -> str:
    if as_json:
        return json.dumps(
            {
                "package": result.package,
                "ok": result.ok,
                "exit": result.exit_code,
                "failures": result.failures,
                "warnings": result.warnings,
                "leaves": result.leaves,
                "credited": result.credited,
                "glue": result.glue,
                "error": result.error,
            },
            indent=2,
            sort_keys=True,
        )
    lines: list[str] = []
    if result.error is not None:
        lines.append(f"error: {result.error}")
        return "\n".join(lines)
    for warning in result.warnings:
        lines.append(f"warning {warning}")
    if result.ok:
        lines.append(f"ADMIT {result.package}: {len(result.leaves)} obligation(s)")
        lines.extend(f"  - {leaf}" for leaf in result.leaves)
    else:
        lines.append(f"REJECT {result.package}: {len(result.failures)} failure(s)")
        lines.extend(f"  {failure}" for failure in result.failures)
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="python3 -m tools.intake.skeleton_validate",
        description="Validate a curated skeleton package (ADR-081 / SPEC-081-A).",
    )
    parser.add_argument("package", help="path to the skeleton package directory")
    parser.add_argument("--strict", action="store_true", help="treat padding warnings as failures")
    parser.add_argument("--build", action="store_true", help="run Lean checks 6-7 (type-check + credited/glue)")
    parser.add_argument("--json", action="store_true", help="emit a structured JSON report")
    parser.add_argument(
        "--registry",
        default=None,
        help="path to the admitted-domains registry (default: docs/governance/admitted-domains.json)",
    )
    args = parser.parse_args(argv)

    try:
        registry = load_registry(args.registry) if args.registry else load_registry()
    except RegistryError as exc:
        print(f"error: registry invalid: {exc}", file=sys.stderr)
        return EXIT_ERROR

    try:
        result = validate_package(
            Path(args.package), registry, strict=args.strict, build=args.build
        )
    except Exception as exc:  # never crash the gate — a malformed package is exit 2
        print(f"error: {exc}", file=sys.stderr)
        return EXIT_ERROR
    stream = sys.stdout if result.ok else sys.stderr
    print(_render(result, args.json), file=stream)
    return result.exit_code


if __name__ == "__main__":
    raise SystemExit(main())
