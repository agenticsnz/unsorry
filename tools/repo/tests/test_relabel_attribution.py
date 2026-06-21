"""Tests for the attribution relabel sweep (pure transform)."""
from __future__ import annotations

from pathlib import Path

from tools.repo.relabel_attribution import main, relabel_record


def _prov(solver="ohdearquant", agent="mac-158f", provider="claude", model="template-zmod-decide"):
    return (f"⟦Π:Provenance⟧{{solver≜{solver}; agent≜{agent}; "
            f"provider≜{provider}; model≜{model}}}\n")


def test_template_proof_relabelled():
    new, changed = relabel_record(_prov())
    assert changed is True
    assert "provider≜python" in new and "model≜sympy" in new
    assert "provider≜claude" not in new and "template-" not in new
    assert "solver≜ohdearquant" in new   # credit untouched


def test_idempotent():
    once, _ = relabel_record(_prov())
    twice, changed = relabel_record(once)
    assert changed is False and twice == once


def test_genuine_llm_proof_by_same_agent_untouched():
    # mac-158f also has real claude proofs (e.g. model≜sonnet) — must stay claude.
    text = _prov(model="sonnet")
    assert relabel_record(text) == (text, False)


def test_seedkit_fixture_untouched():
    # seedkit emits template-* but as provider≜seedkit — not the mislabelled set.
    text = _prov(provider="seedkit")
    assert relabel_record(text) == (text, False)


def test_other_agent_untouched():
    text = _prov(agent="oma-2-c05e")
    assert relabel_record(text) == (text, False)


def test_end_to_end_apply(tmp_path: Path, capsys):
    idx = tmp_path / "library" / "index"
    idx.mkdir(parents=True)
    (idx / "a.aisp").write_text("⟦Ω:Lemma⟧{}\n" + _prov(), encoding="utf-8")          # match
    (idx / "b.aisp").write_text("⟦Ω:Lemma⟧{}\n" + _prov(model="sonnet"), encoding="utf-8")  # keep
    runs = tmp_path / "proof-runs"
    runs.mkdir()
    (runs / "g.mac-158f.x.aisp").write_text("⟦Ω:Run⟧{}\n" + _prov(model="template-ring-cofactor"),
                                            encoding="utf-8")  # match

    assert main([str(tmp_path), "--apply"]) == 0
    assert "relabelled 2 record(s)" in capsys.readouterr().out
    assert "model≜sympy" in (idx / "a.aisp").read_text(encoding="utf-8")
    assert "model≜sonnet" in (idx / "b.aisp").read_text(encoding="utf-8")   # untouched
    assert "model≜sympy" in (runs / "g.mac-158f.x.aisp").read_text(encoding="utf-8")
    # second run is a no-op (idempotent)
    assert main([str(tmp_path), "--apply"]) == 0
    assert "relabelled 0 record(s)" in capsys.readouterr().out


def test_cli_accepts_workflow_argv(tmp_path: Path, monkeypatch, capsys):
    # Regression: attribution-relabel.yml invokes us with a *positional* root
    # (`--apply .`). The argv the workflow actually runs must parse, or every
    # sweep dies with `error: unrecognized arguments: .` (exit 2) before doing
    # any work — which is exactly how the sweep shipped born-broken.
    monkeypatch.chdir(tmp_path)
    assert main(["--apply", "."]) == 0           # the workflow's exact argv
    assert main(["."]) == 0                       # positional dry-run
    assert main(["--apply"]) == 0                 # bare flag still defaults root to .
