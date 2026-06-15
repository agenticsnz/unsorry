"""Targets board generator tests (ADR-012)."""
from __future__ import annotations

from pathlib import Path

from tools.sourcing.targets_board import main, render, rows


def _seed(root: Path, gid: str, status: str, diff: int, backlog: str | None):
    (root / "goals").mkdir(parents=True, exist_ok=True)
    (root / "goals" / f"{gid}.aisp").write_text(
        f"⟦Ω:Goal⟧{{ id≜{gid} phase≜prove status≜{status} difficulty≜{diff} }}\n",
        encoding="utf-8")
    if backlog is not None:
        (root / "backlog").mkdir(parents=True, exist_ok=True)
        (root / "backlog" / f"{gid}.md").write_text(backlog, encoding="utf-8")


def test_rows_reads_status_and_provenance(tmp_path):
    _seed(tmp_path, "sum-squares", "open", 2,
          "# sum-squares\n\nSum of the first n squares.\n\n"
          "- **Source:** Freek 100\n- **Reference:** Concrete Mathematics §2.5\n"
          "- **Absence:** no-local-match (rev abc, 2026-06-10)\n")
    r = rows(tmp_path)
    assert len(r) == 1
    assert r[0]["title"] == "Sum of the first n squares."
    assert r[0]["source"] == "Freek 100"
    assert r[0]["reference"] == "Concrete Mathematics §2.5"
    assert r[0]["status"] == "open"


def test_rows_reads_archived_source_provenance(tmp_path):
    _seed(tmp_path, "archived-goal", "archived", 3, None)
    goal = tmp_path / "goals" / "archived-goal.aisp"
    goal.write_text(
        "⟦Ω:Goal⟧{ id≜archived-goal phase≜prove status≜archived difficulty≜3 }\n"
        "⟦Σ:Source⟧{ src≜packages/unsorry-archive-0002/backlog/archived-goal.md }\n",
        encoding="utf-8",
    )
    md = tmp_path / "packages" / "unsorry-archive-0002" / "backlog" / "archived-goal.md"
    md.parent.mkdir(parents=True)
    md.write_text(
        "# archived-goal\n\nThe archived target title.\n\n"
        "- **Source:** Archived source\n- **Reference:** Archived reference\n",
        encoding="utf-8",
    )

    r = rows(tmp_path)

    assert r[0]["title"] == "The archived target title."
    assert r[0]["source"] == "Archived source"
    assert r[0]["reference"] == "Archived reference"


def test_rows_joins_multiline_title_paragraph(tmp_path):
    _seed(
        tmp_path,
        "multiline-title",
        "open",
        1,
        "# multiline-title\n\n"
        "The first title line\n"
        "continues on the next line.\n\n"
        "- **Source:** Source field\n",
    )

    assert rows(tmp_path)[0]["title"] == "The first title line continues on the next line."


def test_proved_marker_overrides_record_status(tmp_path):
    _seed(tmp_path, "g", "open", 1, None)
    (tmp_path / "library" / "index").mkdir(parents=True, exist_ok=True)
    (tmp_path / "library" / "index" / ("0" * 64 + ".aisp")).write_text(
        "⟦Ω:Lemma⟧{sha≜x; goal≜g; name≜g}\n", encoding="utf-8")
    assert rows(tmp_path)[0]["status"] == "proved"


def test_only_prove_goals_listed(tmp_path):
    _seed(tmp_path, "p", "open", 1, None)
    (tmp_path / "goals" / "t.aisp").write_text(
        "⟦Ω:Goal⟧{ id≜t phase≜translate status≜open }\n", encoding="utf-8")
    ids = {r["id"] for r in rows(tmp_path)}
    assert ids == {"p"}


def test_render_is_deterministic_and_has_counts(tmp_path):
    _seed(tmp_path, "a", "open", 1, None)
    _seed(tmp_path, "b", "open", 1, None)
    out1 = render(tmp_path)
    out2 = render(tmp_path)
    assert out1 == out2
    assert "2 open · 0 proved · 2 total" in out1


def test_check_mode_detects_drift(tmp_path):
    _seed(tmp_path, "a", "open", 1, None)
    (tmp_path / "docs").mkdir(parents=True, exist_ok=True)
    assert main(["--check", str(tmp_path)]) == 1  # docs/targets.md missing → stale
    (tmp_path / "docs" / "targets.md").write_text(render(tmp_path), encoding="utf-8")
    assert main(["--check", str(tmp_path)]) == 0


def test_upstream_column_reads_packet_status(tmp_path):
    # ADR-020: the board surfaces the packet's Status line; '—' without one.
    _seed(tmp_path, "novel-lemma", "open", 2,
          "# novel-lemma\n\nA lemma.\n\n- **Absence:** no-local-match\n")
    assert rows(tmp_path)[0]["upstream"] == "—"
    up = tmp_path / "docs" / "upstream"
    up.mkdir(parents=True)
    (up / "novel-lemma.md").write_text(
        "# Upstream packet: `novel-lemma`\n\nStatus: packet-ready · generated\n",
        encoding="utf-8")
    assert rows(tmp_path)[0]["upstream"] == "packet-ready"
    assert "[packet-ready](upstream/novel-lemma.md)" in render(tmp_path)
