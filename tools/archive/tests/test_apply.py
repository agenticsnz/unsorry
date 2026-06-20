from pathlib import Path

from tools.archive import apply


def _write(p: Path, text: str) -> None:
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text, encoding="utf-8")


def test_decomposition_components_unions_parent_and_subs(tmp_path: Path):
    _write(
        tmp_path / "decompositions" / "p.agent.aisp",
        "𝔸5.1.decomp.p.agent@2026-06-14\n"
        "γ≔unsorry.decomposition\n"
        "⟦Ω:Decomp⟧{parent≜p; agent≜agent}\n"
        "⟦Σ:Subs⟧{\n"
        "  sub₁≜⟨id≜p-s1,sha≜aa⟩\n"
        "  sub₂≜⟨id≜p-s2,sha≜bb⟩\n"
        "}\n",
    )
    comps = apply.decomposition_components(tmp_path)
    assert comps["p"] == comps["p-s1"] == comps["p-s2"]
    assert comps["p"] == frozenset({"p", "p-s1", "p-s2"})
    # a goal in no decomposition is absent (treated as standalone by select_block)
    assert "standalone" not in comps


def test_retire_rewrites_status_and_prefixes_paths(tmp_path: Path):
    goal = tmp_path / "goals" / "g.aisp"
    _write(
        goal,
        "𝔸5.1.goal.g@2026-06-14\n"
        "γ≔unsorry.goal\n"
        "⟦Ω:Goal⟧{\n  id≜g\n  phase≜prove\n  status≜proved\n}\n"
        "⟦Σ:Source⟧{\n  src≜backlog/g.md\n}\n"
        "⟦Λ:Artifact⟧{\n  lean≜goals/g.lean\n  sha≜abc\n}\n",
    )
    apply._retire_active_record(tmp_path, "g", "unsorry-archive-0005")
    out = goal.read_text(encoding="utf-8")
    assert "status≜archived" in out and "status≜proved" not in out
    assert "src≜packages/unsorry-archive-0005/backlog/g.md" in out
    assert "lean≜packages/unsorry-archive-0005/goals/g.lean" in out
    assert "sha≜abc" in out  # sha unchanged


def test_retire_never_prefixes_empty_sentinel(tmp_path: Path):
    goal = tmp_path / "goals" / "seed.aisp"
    _write(
        goal,
        "𝔸5.1.goal.seed@2026-06-14\n"
        "γ≔unsorry.goal\n"
        "⟦Ω:Goal⟧{\n  id≜seed\n  phase≜translate\n  status≜proved\n}\n"
        "⟦Σ:Source⟧{\n  src≜backlog/seed.md\n}\n"
        "⟦Λ:Artifact⟧{\n  lean≜∅\n}\n",
    )
    apply._retire_active_record(tmp_path, "seed", "unsorry-archive-0005")
    out = goal.read_text(encoding="utf-8")
    assert "lean≜∅" in out  # the empty sentinel is never prefixed
    assert "packages/unsorry-archive-0005/∅" not in out


def _proved(goal: str, theorem: str, module_path: str):
    from tools.archive.plan import ProvedGoal
    return ProvedGoal(
        goal=goal, sha="a" * 4, theorem=theorem, module=f"Unsorry.{goal}",
        module_path=module_path, goal_path=f"goals/{goal}.lean",
        index_path=f"library/index/{'a' * 4}.aisp", proof_run_paths=(),
        proved_at="2026-06-14T00:00:00Z",
    )


def test_binding_satisfiable_when_theorem_in_own_module(tmp_path: Path):
    _write(tmp_path / "library" / "Unsorry" / "Foo.lean",
           "import Mathlib\n\ntheorem foo : True := trivial\n")
    g = _proved("foo", "foo", "library/Unsorry/Foo.lean")
    assert apply._binding_unsatisfiable_in_block(tmp_path, [g]) == set()


def test_binding_unsatisfiable_when_theorem_module_not_in_block(tmp_path: Path):
    # The goal's binding theorem lives in a module that is NOT among the block's
    # modules (the nat-sq-lt-two-pow-s2 / block 0033 pathology). It must be flagged.
    _write(tmp_path / "library" / "Unsorry" / "Bar.lean",
           "import Mathlib\n\ntheorem unrelated : True := trivial\n")
    g = _proved("parent", "step_lemma", "library/Unsorry/Bar.lean")
    assert apply._binding_unsatisfiable_in_block(tmp_path, [g]) == {"parent"}


def test_binding_private_decl_is_not_referenceable(tmp_path: Path):
    # A private declaration cannot be the binding target (check_statement_binding
    # rule) -> unsatisfiable even though the name textually appears.
    _write(tmp_path / "library" / "Unsorry" / "Baz.lean",
           "import Mathlib\n\nprivate theorem hidden : True := trivial\n")
    g = _proved("g", "hidden", "library/Unsorry/Baz.lean")
    assert apply._binding_unsatisfiable_in_block(tmp_path, [g]) == {"g"}


def test_binding_satisfied_by_shared_module_in_block(tmp_path: Path):
    # Theorem declared in ANOTHER goal's module that IS co-located in the block.
    _write(tmp_path / "library" / "Unsorry" / "Shared.lean",
           "import Mathlib\n\ntheorem shared_lemma : True := trivial\n")
    _write(tmp_path / "library" / "Unsorry" / "User.lean",
           "import Mathlib\n\ntheorem user_thm : True := trivial\n")
    user = _proved("user", "user_thm", "library/Unsorry/User.lean")
    parent = _proved("parent", "shared_lemma", "library/Unsorry/Shared.lean")
    assert apply._binding_unsatisfiable_in_block(tmp_path, [user, parent]) == set()
