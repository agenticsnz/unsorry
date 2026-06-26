"""Tests for the finalization-recovery selectors (ADR-105 / SPEC-105-A).

Pure-function coverage for the two gaps: arming same-repo prove PRs the swarm
left unenrolled, and classifying a gate-a failure as a recoverable cancellation
cascade vs a genuine block. No ``gh`` — selection is stdin-driven.
"""
from __future__ import annotations

import io
import json

import pytest

from tools.repo.finalization_recovery import (
    gate_failure_is_cancellation,
    main,
    select_arm,
    should_arm,
    within_allow,
)


# --- should_arm -------------------------------------------------------------

def _prove_pr(**over):
    pr = {
        "number": 1,
        "title": "prove(foo-bar): foo_bar by claude-web",
        "isCrossRepository": False,
        "isDraft": False,
        "autoMergeRequest": None,
        "mergeStateStatus": "CLEAN",
        "files": [{"path": "library/Unsorry/Foo.lean"}, {"path": "goals/foo.lean"}],
    }
    pr.update(over)
    return pr


def test_arms_plain_same_repo_prove_pr():
    assert should_arm(_prove_pr()) is True


def test_skips_cross_repo_pr_owned_by_fork_enabler():
    # ADR-068: cross-repo arming is the fork-automerge-enabler's job — don't double-arm.
    assert should_arm(_prove_pr(isCrossRepository=True)) is False


def test_skips_already_armed():
    assert should_arm(_prove_pr(autoMergeRequest={"enabledAt": "..."})) is False


def test_skips_draft():
    assert should_arm(_prove_pr(isDraft=True)) is False


def test_skips_non_prove_title():
    assert should_arm(_prove_pr(title="docs: tidy README")) is False
    assert should_arm(_prove_pr(title="chore(sourcing): add targets")) is False


def test_skips_dirty_conflict():
    assert should_arm(_prove_pr(mergeStateStatus="DIRTY")) is False


def test_skips_diff_outside_allow_paths():
    # touches a gate / workflow → not a plain proof, never arm by automation
    assert should_arm(_prove_pr(files=[{"path": ".github/workflows/gate-a.yml"}])) is False
    assert should_arm(_prove_pr(files=[{"path": "tools/gate_a/x.py"}])) is False


def test_fail_closed_on_unseen_diff():
    # no files visible → cannot prove it is proof-only → do not arm
    assert should_arm(_prove_pr(files=[])) is False
    assert should_arm(_prove_pr(files=None)) is False


def test_within_allow_requires_every_path_allowed():
    assert within_allow(["library/A.lean", "goals/b.lean"]) is True
    assert within_allow(["library/A.lean", "tools/x.py"]) is False
    assert within_allow([]) is False


def test_select_arm_orders_and_caps():
    prs = [_prove_pr(number=9), _prove_pr(number=2), _prove_pr(number=5),
           _prove_pr(number=3, isCrossRepository=True)]  # 3 excluded
    assert select_arm(prs) == [2, 5, 9]
    assert select_arm(prs, limit=2) == [2, 5]
    assert select_arm(prs, limit=0) == []


# --- gate_failure_is_cancellation ------------------------------------------

def test_cancellation_cascade_is_recoverable():
    # an audit shard cancelled → cover cascaded to failure → gate-a failure.
    jobs = [
        {"name": "gate-a-prepare", "conclusion": "success"},
        {"name": "gate-a-audit (1)", "conclusion": "cancelled"},
        {"name": "gate-a-audit-cover", "conclusion": "failure"},
        {"name": "gate-a", "conclusion": "failure"},
    ]
    assert gate_failure_is_cancellation(jobs) is True


def test_prepare_cancelled_then_replay_cover_cascade_is_recoverable():
    jobs = [
        {"name": "gate-a-prepare", "conclusion": "cancelled"},
        {"name": "gate-a-replay-cover", "conclusion": "failure"},
        {"name": "gate-a", "conclusion": "failure"},
    ]
    assert gate_failure_is_cancellation(jobs) is True


def test_genuine_leaf_failure_is_not_recoverable():
    # a real proof failure (nanoda rejects) — never auto-rerun, it would just refail.
    jobs = [
        {"name": "gate-a-prepare", "conclusion": "success"},
        {"name": "gate-a-nanoda", "conclusion": "failure"},
        {"name": "gate-a-audit (0)", "conclusion": "cancelled"},
        {"name": "gate-a", "conclusion": "failure"},
    ]
    assert gate_failure_is_cancellation(jobs) is False


def test_admission_failure_is_not_recoverable():
    # admission is a deliberate policy block (per-author cap) — leave it.
    jobs = [
        {"name": "admission", "conclusion": "failure"},
        {"name": "gate-a-audit (1)", "conclusion": "cancelled"},
        {"name": "gate-a-audit-cover", "conclusion": "failure"},
        {"name": "gate-a", "conclusion": "failure"},
    ]
    assert gate_failure_is_cancellation(jobs) is False


def test_no_cancellation_is_not_recoverable():
    jobs = [
        {"name": "gate-a-prepare", "conclusion": "success"},
        {"name": "gate-a-replay-cover", "conclusion": "failure"},
        {"name": "gate-a", "conclusion": "failure"},
    ]
    assert gate_failure_is_cancellation(jobs) is False


def test_all_success_is_not_recoverable():
    jobs = [{"name": "gate-a", "conclusion": "success"}]
    assert gate_failure_is_cancellation(jobs) is False


# --- CLI --------------------------------------------------------------------

def test_cli_arm(monkeypatch, capsys):
    prs = [_prove_pr(number=7), _prove_pr(number=4, isCrossRepository=True)]
    monkeypatch.setattr("sys.stdin", io.StringIO(json.dumps(prs)))
    assert main(["arm"]) == 0
    assert capsys.readouterr().out.split() == ["7"]


def test_cli_is_cancellation_true(monkeypatch, capsys):
    jobs = [{"name": "gate-a-audit (1)", "conclusion": "cancelled"},
            {"name": "gate-a-audit-cover", "conclusion": "failure"}]
    monkeypatch.setattr("sys.stdin", io.StringIO(json.dumps(jobs)))
    assert main(["is-cancellation"]) == 0
    assert capsys.readouterr().out.strip() == "true"


def test_cli_is_cancellation_false_on_genuine(monkeypatch, capsys):
    jobs = [{"name": "gate-a-nanoda", "conclusion": "failure"}]
    monkeypatch.setattr("sys.stdin", io.StringIO(json.dumps(jobs)))
    assert main(["is-cancellation"]) == 0
    assert capsys.readouterr().out.strip() == "false"


def test_cli_unknown_command_is_usage_error(monkeypatch):
    monkeypatch.setattr("sys.stdin", io.StringIO("[]"))
    assert main(["bogus"]) == 2
