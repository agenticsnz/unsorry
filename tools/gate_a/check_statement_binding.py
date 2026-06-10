"""Statement-binding gate (ADR-011, SPEC-011-A): regenerate the kernel binding
obligation for every proved goal, so Gate A — not the contributor — controls
what "proved this statement" means.

For each `library/index/<sha>.aisp` (a proved goal `<g>`), this writes
`library/Unsorry/<Camel>Binding.lean`:

    import Unsorry.<Camel>
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

from tools.lean_sig import camel_name, foralltype, theorem_name

_GOAL_RE = re.compile(r"goal≜([A-Za-z0-9][A-Za-z0-9-]*)")
BINDING_SUFFIX = "Binding.lean"


def _module_declaring(unsorry_dir: Path, name: str) -> str | None:
    """The `Unsorry.<Stem>` module that declares `theorem/lemma <name>` — found
    by content, not by an assumed path (so a grandfathered module such as
    `Basic.lean` is handled, not only the `<Camel>.lean` convention)."""
    decl = re.compile(rf"\b(?:theorem|lemma)\s+{re.escape(name)}\b")
    for path in sorted(unsorry_dir.glob("*.lean")):
        if path.name.endswith(BINDING_SUFFIX):
            continue
        if decl.search(path.read_text(encoding="utf-8")):
            return f"Unsorry.{path.stem}"
    return None


def proved_goals(tree: Path):
    """Yield goal ids that have a library/index entry (the proved marker)."""
    index_dir = tree / "library" / "index"
    if index_dir.is_dir():
        for entry in sorted(index_dir.glob("*.aisp")):
            m = _GOAL_RE.search(entry.read_text(encoding="utf-8"))
            if m:
                yield m.group(1)


def generate(tree: Path) -> int:
    errors = 0
    unsorry_dir = tree / "library" / "Unsorry"
    for goal in proved_goals(tree):
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
        binding_path.write_text(
            f"import {module}\n\n"
            f"theorem {name}_binding_check : {ftype} := {name}\n",
            encoding="utf-8",
        )
        print(f"generated {binding_path.relative_to(tree)} ({module}) : {ftype}")
    if errors:
        print(f"{errors} binding generation error(s)", file=sys.stderr)
    return 1 if errors else 0


def clean(tree: Path) -> int:
    removed = 0
    for path in (tree / "library" / "Unsorry").glob(f"*{BINDING_SUFFIX}"):
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
