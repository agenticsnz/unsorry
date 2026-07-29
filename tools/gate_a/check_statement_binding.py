"""Statement-binding gate (ADR-011, SPEC-011-A): regenerate the kernel binding
obligation for every proved goal, so Gate A — not the contributor — controls
what "proved this statement" means.

For each proof index entry (a proved goal `<g>`), this writes a binding beside the
module it binds — `library/Unsorry/<Camel>Binding.lean` for a repo-pinned proof, and
`targets/<suite>/_verify/library/Unsorry/<Camel>Binding.lean` for one proved at a
suite pin (ADR-099/ADR-116):

    import Unsorry.<Camel>
    <open commands of goals/<g>.lean, if any>
    set_option linter.unusedVariables false in
    theorem <name>_binding_check : <∀-type of goals/<g>.lean> := <name>

The asserted type is the goal's own statement (`tools.lean_sig.foralltype`);
the proof term is the merged theorem. Gate A's `lake build UnsorryLibrary
--wfail` then builds these — and the obligation type-checks **iff** the proved
theorem's type is definitionally equal to (or more general than) the goal's. A
vacuous or weakened restatement under the goal's name — the #64 class — fails
to inhabit the goal type, so the binding build fails and Gate A goes red.

Because Gate A regenerates the bindings here from the goals (rather than
trusting a committed binding), a contributor cannot weaken or omit them.

Usage:
  python3 -m tools.gate_a.check_statement_binding generate <tree-root>
  python3 -m tools.gate_a.check_statement_binding clean    <tree-root>
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

from tools.lean_sig import camel_name, foralltype, import_lines, open_lines, theorem_name

_GOAL_RE = re.compile(r"goal≜([A-Za-z0-9][A-Za-z0-9-]*)")
_STATUS_RE = re.compile(r"status≜([A-Za-z0-9-]+)")
BINDING_SUFFIX = "Binding.lean"


def _module_declaring(unsorry_dir: Path, name: str) -> str | None:
    """The `Unsorry.<Stem>` module that declares a **referenceable** `theorem/lemma
    <name>` — found by content, not by an assumed path (so a grandfathered module
    such as `Basic.lean` is handled, not only the `<Camel>.lean` convention).

    A `private` declaration is skipped: the binding module imports this one and
    references the name by value, which a `private` decl does not export → "unknown
    identifier". This bit goal nat-sq-lt-two-pow-s2 (#679/#963/#1173): a recompose
    proof in the alphabetically-earlier `NatSqLtTwoPow` re-used the sub-lemma name
    `sq_lt_two_pow_step_from_five` as a `private` helper, so the binding bound to
    that instead of the public proof in `NatSqLtTwoPowS2` and every attempt failed."""
    decl = re.compile(rf"^(?P<mods>[^\n]*?)\b(?:theorem|lemma)\s+{re.escape(name)}\b", re.MULTILINE)
    for path in sorted(unsorry_dir.glob("*.lean")):
        if path.name.endswith(BINDING_SUFFIX):
            continue
        for m in decl.finditer(path.read_text(encoding="utf-8")):
            if "private" in m.group("mods").split():
                continue  # not exported — cannot be the binding target
            return f"Unsorry.{path.stem}"
    return None


def proof_libraries(tree: Path) -> list[Path]:
    """Every library whose index marks proofs Gate A must bind.

    The repo `library/`, plus each suite verification package. A benchmark
    obligation — and, through the decomposition graph, its sub-lemmas — proves at
    its SUITE's own toolchain+mathlib pin (ADR-099/ADR-116), so both its module and
    its index entry live in `targets/<suite>/_verify/library/` and never reach the
    repo library. Reading only the repo index meant no binding was ever generated
    for such a proof, and since `check_in_proof` DELETES the agent's own binding
    before the PR (`swarm/agent.sh`), statement identity went unverified by Gate A
    entirely — the inversion ADR-011 exists to prevent (#7191).
    """
    libraries = [tree / "library"]
    targets = tree / "targets"
    if targets.is_dir():
        libraries.extend(
            sorted(index.parent for index in targets.glob("*/_verify/library/index"))
        )
    return [lib for lib in libraries if (lib / "index").is_dir()]


def proved_goals(tree: Path):
    """Yield ``(goal id, owning library)`` for every proof index entry.

    The library is carried with the goal because the binding must be written beside
    the module it binds — a suite proof's module is only importable from inside its
    own suite package.
    """
    for library in proof_libraries(tree):
        for entry in sorted((library / "index").glob("*.aisp")):
            m = _GOAL_RE.search(entry.read_text(encoding="utf-8"))
            if m:
                yield m.group(1), library


def goal_status(tree: Path, goal: str) -> str | None:
    path = tree / "goals" / f"{goal}.aisp"
    if not path.is_file():
        return None
    m = _STATUS_RE.search(path.read_text(encoding="utf-8"))
    return m.group(1) if m else None


def generate(tree: Path) -> int:
    errors = 0
    for goal, library in proved_goals(tree):
        unsorry_dir = library / "Unsorry"
        if goal_status(tree, goal) == "archived":
            print(f"skipped {goal}: archived proof package owns the binding")
            continue
        goal_lean = tree / "goals" / f"{goal}.lean"
        if not goal_lean.is_file():
            # No Lean goal statement to bind against — a translate-phase or
            # grandfathered manually-proved lemma (e.g. the first lemma, in
            # Basic.lean). Skipped, not failed: there is no goal type to assert.
            # The prove cycle always emits goals/<g>.lean, so every swarm-proved
            # goal IS bound; this only spares pre-binding manual entries.
            print(f"skipped {goal}: no goal statement (translate/grandfathered)")
            continue
        text = goal_lean.read_text(encoding="utf-8")
        try:
            name = theorem_name(text)
            ftype = foralltype(text)
        except ValueError as exc:
            print(f"BINDING-ERROR {goal}: {exc}", file=sys.stderr)
            errors += 1
            continue
        module = _module_declaring(unsorry_dir, name)
        if module is None:
            print(f"BINDING-ERROR {goal}: no library module declares '{name}'",
                  file=sys.stderr)
            errors += 1
            continue
        binding_path = unsorry_dir / f"{camel_name(goal)}{BINDING_SUFFIX}"
        # The goal's own `open` commands travel with the type: a statement
        # written under `open Finset` names `range` unqualified, and the
        # obligation must elaborate in that same namespace context. The opens
        # come from the ADR-018-immutable goal file, never from the prover's
        # module, so this adds no tampering surface.
        imports = "".join(f"{i}\n" for i in import_lines(text))
        opens = "".join(f"{o}\n" for o in open_lines(text))
        # linter.unusedVariables is suppressed because the obligation restates
        # the goal's binders verbatim: a named hypothesis binder following an
        # implicit binder (e.g. `∀ {n : ℕ} (hn : 1 < n), …`) is eta-expanded
        # by the elaborator and flagged unused, failing the --wfail build for
        # any correct proof of such a goal. The binding's force comes from
        # type-checking, not lints; the file is regenerated glue, never
        # committed (SPEC-011-A).
        binding_path.write_text(
            f"{imports}"
            f"import {module}\n\n"
            f"{opens}"
            f"set_option linter.unusedVariables false in\n"
            f"theorem {name}_binding_check : {ftype} := {name}\n",
            encoding="utf-8",
        )
        print(f"generated {binding_path.relative_to(tree)} ({module}) : {ftype}")
    if errors:
        print(f"{errors} binding generation error(s)", file=sys.stderr)
    return 1 if errors else 0


def clean(tree: Path) -> int:
    removed = 0
    for path in sorted(
        p
        for library in proof_libraries(tree)
        for p in (library / "Unsorry").glob(f"*{BINDING_SUFFIX}")
    ):
        path.unlink()
        removed += 1
    print(f"removed {removed} binding module(s)")
    return 0


def main(argv: list[str] | None = None) -> int:
    argv = sys.argv[1:] if argv is None else argv
    if len(argv) != 2 or argv[0] not in ("generate", "clean"):
        print(__doc__)
        return 2
    tree = Path(argv[1])
    return generate(tree) if argv[0] == "generate" else clean(tree)


if __name__ == "__main__":
    raise SystemExit(main())
