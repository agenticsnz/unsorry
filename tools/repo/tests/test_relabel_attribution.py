"""Tests for the attribution relabel sweep (pure transform)."""
from __future__ import annotations

from pathlib import Path

from tools.repo.relabel_attribution import (
    correct_difficulty,
    index_is_mac158f,
    index_is_seedkit,
    index_is_template_fixture,
    main,
    relabel_record,
)


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


def test_seedkit_provider_relabelled_to_lean():
    # ADR-087 reverses the old exclusion: seedkit fixtures (provider≜seedkit) are
    # honest Lean proofs and ARE relabelled to lean/decide | lean/ring.
    zmod = _prov(solver="chat-bit-01", agent="seedkit", provider="seedkit",
                 model="template-zmod-decide")
    new, changed = relabel_record(zmod)
    assert changed and "provider≜lean" in new and "model≜decide" in new
    assert "provider≜seedkit" not in new and "template-" not in new
    assert "solver≜chat-bit-01" in new   # credit untouched

    ring = _prov(agent="seedkit", provider="seedkit", model="template-induction-ring")
    new2, changed2 = relabel_record(ring)
    assert changed2 and "provider≜lean" in new2 and "model≜ring" in new2
    assert "template-" not in new2


def test_claude_web_induction_ring_relabelled_to_lean_ring():
    # chat-bit-01's induction;ring fixtures (mislabelled provider≜claude) → lean/ring.
    text = _prov(solver="chat-bit-01", agent="claude-web", provider="claude",
                 model="template-induction-ring")
    new, changed = relabel_record(text)
    assert changed and "provider≜lean" in new and "model≜ring" in new
    assert "provider≜claude" not in new and "template-" not in new
    assert "solver≜chat-bit-01" in new   # credit untouched


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


def test_claude_web_zmod_decide_relabelled_to_lean():
    # chat-bit-01's claude-web `template-zmod-decide` proofs are a deterministic Lean
    # kernel `decide` over a finite ZMod, not an LLM solve — honest record is lean/decide.
    text = _prov(solver="chat-bit-01", agent="claude-web", model="template-zmod-decide")
    new, changed = relabel_record(text)
    assert changed is True
    assert "provider≜lean" in new and "model≜decide" in new
    assert "provider≜claude" not in new and "template-zmod-decide" not in new
    assert "solver≜chat-bit-01" in new   # credit untouched


def test_claude_web_lean_decide_idempotent():
    once, _ = relabel_record(
        _prov(solver="chat-bit-01", agent="claude-web", model="template-zmod-decide"))
    twice, changed = relabel_record(once)
    assert changed is False and twice == once


def test_claude_web_genuine_llm_untouched():
    # A real claude-web LLM proof (model≜opus, not the decide template) stays claude.
    text = _prov(agent="claude-web", model="opus")
    assert relabel_record(text) == (text, False)


def test_both_rules_apply_in_one_sweep(tmp_path: Path, capsys):
    idx = tmp_path / "library" / "index"
    idx.mkdir(parents=True)
    (idx / "mac.aisp").write_text("⟦Ω:Lemma⟧{}\n" + _prov(), encoding="utf-8")  # → python/sympy
    (idx / "web.aisp").write_text(
        "⟦Ω:Lemma⟧{}\n" + _prov(solver="chat-bit-01", agent="claude-web",
                                 model="template-zmod-decide"),
        encoding="utf-8")  # → lean/decide

    assert main([str(tmp_path), "--apply"]) == 0
    assert "relabelled 2 record(s)" in capsys.readouterr().out
    mac = (idx / "mac.aisp").read_text(encoding="utf-8")
    web = (idx / "web.aisp").read_text(encoding="utf-8")
    assert "provider≜python" in mac and "model≜sympy" in mac
    assert "provider≜lean" in web and "model≜decide" in web
    assert "template-" not in mac and "template-" not in web


# --- ADR-087: seedkit difficulty backfill ---

def _goal_record(gid="gzmod-12-pow-six-sub-pow-four", difficulty=3):
    return (f"𝔸5.1.goal.{gid}@2026-06-23\n"
            f"⟦Ω:Goal⟧{{\n  id≜{gid}\n  phase≜prove\n  status≜proved\n"
            f"  difficulty≜{difficulty}\n}}\n")


def _index_for(gid, agent="seedkit", provider="lean", model="decide"):
    return (f"⟦Ω:Lemma⟧{{sha≜abc; goal≜{gid}; name≜x}}\n"
            + _prov(solver="chat-bit-01", agent=agent, provider=provider, model=model))


def test_correct_difficulty():
    new, changed = correct_difficulty(_goal_record(difficulty=4))
    assert changed and "difficulty≜1" in new and "difficulty≜4" not in new


def test_correct_difficulty_idempotent_and_leaves_low_alone():
    once, _ = correct_difficulty(_goal_record(difficulty=5))
    twice, changed = correct_difficulty(once)
    assert changed is False and twice == once
    low = _goal_record(difficulty=1)
    assert correct_difficulty(low) == (low, False)


def test_index_is_seedkit():
    # relabelled lean engine under a seedkit agent
    assert index_is_seedkit(_prov(agent="seedkit", provider="lean", model="decide"))
    # pre-relabel template under chat-bit-01's agent
    assert index_is_seedkit(_prov(agent="claude-web", provider="seedkit",
                                  model="template-induction-ring"))
    # a genuine LLM proof by the same agent is NOT seedkit
    assert not index_is_seedkit(_prov(agent="claude-web", provider="claude", model="opus"))
    # another contributor's lean/decide is NOT a seedkit fixture
    assert not index_is_seedkit(_prov(agent="oma-2-c05e", provider="lean", model="decide"))


def test_difficulty_backfill_end_to_end(tmp_path: Path, capsys):
    idx = tmp_path / "library" / "index"
    idx.mkdir(parents=True)
    goals = tmp_path / "goals"
    goals.mkdir()
    seed = "gzmod-12-pow-six-sub-pow-four"
    other = "some-real-sourced-goal"
    # a seedkit proof (provider≜seedkit, template) + its inflated goal record
    (idx / "p.aisp").write_text(
        _index_for(seed, agent="seedkit", provider="seedkit", model="template-zmod-decide"),
        encoding="utf-8")
    (goals / f"{seed}.aisp").write_text(_goal_record(seed, difficulty=3), encoding="utf-8")
    # a non-seedkit proof + goal must be left alone
    (idx / "q.aisp").write_text(
        _index_for(other, agent="oma-2-c05e", provider="claude", model="sonnet"),
        encoding="utf-8")
    (goals / f"{other}.aisp").write_text(_goal_record(other, difficulty=3), encoding="utf-8")

    assert main([str(tmp_path), "--apply"]) == 0
    out = capsys.readouterr().out
    assert "corrected 1 goal record(s)" in out
    assert "difficulty≜1" in (goals / f"{seed}.aisp").read_text(encoding="utf-8")
    assert "difficulty≜3" in (goals / f"{other}.aisp").read_text(encoding="utf-8")  # untouched
    # the seedkit index record itself was also relabelled to lean/decide
    assert "provider≜lean" in (idx / "p.aisp").read_text(encoding="utf-8")
    # idempotent second run
    assert main([str(tmp_path), "--apply"]) == 0
    assert "corrected 0 goal record(s)" in capsys.readouterr().out


# --- ADR-088: extend the difficulty backfill to mac-158f sympy templates ---

def test_index_is_mac158f():
    # post-relabel honest python/sympy template
    assert index_is_mac158f(_prov(agent="mac-158f", provider="python", model="sympy"))
    # pre-relabel template-* (still claude-mislabelled)
    assert index_is_mac158f(_prov(agent="mac-158f", provider="claude", model="template-gbinom"))
    # a genuine LLM proof by the same agent is NOT a template fixture
    assert not index_is_mac158f(_prov(agent="mac-158f", provider="claude", model="sonnet"))
    # another agent's python/sympy is not mac-158f
    assert not index_is_mac158f(_prov(agent="oma-2-c05e", provider="python", model="sympy"))


def test_index_is_template_fixture_unions_both_pipelines():
    assert index_is_template_fixture(_prov(agent="seedkit", provider="lean", model="ring"))
    assert index_is_template_fixture(_prov(agent="mac-158f", provider="python", model="sympy"))
    assert not index_is_template_fixture(_prov(agent="oma-2-c05e", provider="claude", model="opus"))


def test_mac158f_difficulty_backfilled_end_to_end(tmp_path: Path, capsys):
    idx = tmp_path / "library" / "index"
    idx.mkdir(parents=True)
    goals = tmp_path / "goals"
    goals.mkdir()
    mac = "gbinom-sum-coeff-seven"
    # a mac-158f sympy template proof + its inflated goal record
    (idx / "m.aisp").write_text(
        _index_for(mac, agent="mac-158f", provider="python", model="sympy"),
        encoding="utf-8")
    (goals / f"{mac}.aisp").write_text(_goal_record(mac, difficulty=4), encoding="utf-8")

    assert main([str(tmp_path), "--apply"]) == 0
    assert "corrected 1 goal record(s)" in capsys.readouterr().out
    assert "difficulty≜1" in (goals / f"{mac}.aisp").read_text(encoding="utf-8")
    # mac-158f provenance was already honest (python/sympy) — unchanged
    assert "provider≜python" in (idx / "m.aisp").read_text(encoding="utf-8")
