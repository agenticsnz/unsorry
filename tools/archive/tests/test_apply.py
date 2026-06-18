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
