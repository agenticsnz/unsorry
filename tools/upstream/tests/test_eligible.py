"""ADR-020 / SPEC-020-A: packet-eligibility scan."""
from __future__ import annotations

from pathlib import Path

from tools.upstream.eligible import eligible


def _mk_root(tmp_path: Path) -> Path:
    root = tmp_path
    (root / "library" / "index").mkdir(parents=True)
    (root / "backlog").mkdir()
    (root / "docs" / "upstream").mkdir(parents=True)
    return root


def _prove(root: Path, goal: str) -> None:
    sha = f"{abs(hash(goal)):064x}"[:64]
    (root / "library" / "index" / f"{sha}.aisp").write_text(
        f"⟦Ω:Lemma⟧{{sha≜{sha}; goal≜{goal}; name≜thm_{goal.replace('-', '_')}}}\n",
        encoding="utf-8",
    )


def _backlog(root: Path, goal: str, absence: bool) -> None:
    body = f"# {goal}\n\nA target.\n"
    if absence:
        body += "- **Absence:** machine-checked no-local-match (grep of pinned mathlib)\n"
    (root / "backlog" / f"{goal}.md").write_text(body, encoding="utf-8")


def test_proved_with_absence_is_eligible(tmp_path):
    root = _mk_root(tmp_path)
    _prove(root, "novel-lemma")
    _backlog(root, "novel-lemma", absence=True)
    assert eligible(root) == ["novel-lemma"]


def test_unproved_is_not_eligible(tmp_path):
    root = _mk_root(tmp_path)
    _backlog(root, "open-target", absence=True)
    assert eligible(root) == []


def test_shakedown_without_absence_field_is_not_eligible(tmp_path):
    # Shakedown-era trivia have backlog prose but no structured Absence
    # provenance — they exist in mathlib already and must never packet.
    root = _mk_root(tmp_path)
    _prove(root, "nat-add-comm-thm")
    _backlog(root, "nat-add-comm-thm", absence=False)
    assert eligible(root) == []


def test_decomposition_sub_without_backlog_is_not_eligible(tmp_path):
    # Machine-minted subs have no backlog entry at all (no absence check was
    # ever run on them) — serve the parent, never packet.
    root = _mk_root(tmp_path)
    _prove(root, "parent-goal-s1")
    assert eligible(root) == []


def test_existing_packet_excludes(tmp_path):
    root = _mk_root(tmp_path)
    _prove(root, "novel-lemma")
    _backlog(root, "novel-lemma", absence=True)
    (root / "docs" / "upstream" / "novel-lemma.md").write_text("packet", encoding="utf-8")
    assert eligible(root) == []


def test_sorted_output(tmp_path):
    root = _mk_root(tmp_path)
    for g in ("zeta-lemma", "alpha-lemma"):
        _prove(root, g)
        _backlog(root, g, absence=True)
    assert eligible(root) == ["alpha-lemma", "zeta-lemma"]


def test_suite_pinned_benchmark_is_never_packet_eligible(tmp_path):
    """A benchmark obligation must not be proposed as a mathlib contribution.

    It is excluded by namespace, not by the absence rule, because a benchmark
    obligation DOES carry a `backlog/<id>.md` with an `Absence:` field — it was
    sourced like any other goal. When `targets_board._proved` was made
    suite-aware without this guard, upstream eligibility went 0 -> 3, offering
    aime-1983-p9, amc12a-2003-p24 and amc12a-2008-p15 to mathlib (#7191 audit).
    """
    from tools.upstream.eligible import eligible

    (tmp_path / "goals").mkdir(parents=True, exist_ok=True)
    (tmp_path / "backlog").mkdir(parents=True, exist_ok=True)
    sha = "b" * 64
    idx = tmp_path / "targets" / "minif2f-v1" / "_verify" / "library" / "index"
    idx.mkdir(parents=True, exist_ok=True)
    (idx / f"{sha}.aisp").write_text(
        f"𝔸5.1.lemma.{sha[:12]}@2026-07-29\nγ≔unsorry.lemma.index\n"
        f"⟦Ω:Lemma⟧{{sha≜{sha}; goal≜bench-goal; name≜bench_goal}}\n"
        "⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩\n",
        encoding="utf-8",
    )
    # Sourced like any other goal: it HAS the absence field.
    (tmp_path / "backlog" / "bench-goal.md").write_text(
        "# bench-goal\n\n- **Absence:** not found in mathlib at rev abc123\n",
        encoding="utf-8",
    )
    assert eligible(tmp_path) == [], "a suite-pinned benchmark reached the upstream pipeline"
