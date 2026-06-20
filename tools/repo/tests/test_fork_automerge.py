"""Tests for the fork auto-merge enabler selector (ADR-068 / SPEC-068-A §6)."""
from __future__ import annotations

import io
import json

from tools.repo import fork_automerge as fa


def _pr(number=1, title="prove(g): t by alice", cross=True, files=None, armed=None):
    return {
        "number": number,
        "title": title,
        "isCrossRepository": cross,
        "files": files if files is not None else [{"path": "library/Unsorry/G.lean"}],
        "autoMergeRequest": armed,
    }


def test_admissible_fork_prove_pr():
    assert fa.is_admissible(_pr())


def test_non_fork_pr_excluded():
    # A same-repo (write-access) prove PR arms its own auto-merge; the enabler
    # only handles cross-repo fork PRs.
    assert not fa.is_admissible(_pr(cross=False))


def test_non_prove_title_excluded():
    for title in ("docs: x", "chore(sourcing): y", "fix(swarm): z", "prove-ish(g): n"):
        assert not fa.is_admissible(_pr(title=title)), title


def test_already_armed_excluded():
    assert not fa.is_admissible(_pr(armed={"enabledAt": "2026-06-17T00:00:00Z"}))


def test_files_outside_allow_paths_excluded():
    # The trust-bearing surfaces: a fork PR touching any of them is never armed.
    for bad in (
        ".github/workflows/gate-a.yml",
        "swarm/agent.sh",
        "tools/gate_b/config.py",
        "lakefile.toml",
        "lean-toolchain",
    ):
        files = [{"path": "library/Unsorry/G.lean"}, {"path": bad}]
        assert not fa.is_admissible(_pr(files=files)), bad


def test_proof_tree_paths_allowed():
    files = [
        {"path": "library/Unsorry/G.lean"},
        {"path": "library/index/abc123.aisp"},
        {"path": "goals/g.aisp"},
        {"path": "proof-runs/g.alice.run.aisp"},
    ]
    assert fa.is_admissible(_pr(files=files))


def test_empty_files_fail_closed():
    # A diff we cannot see is never armed.
    assert not fa.is_admissible(_pr(files=[]))


def test_select_orders_and_limits():
    prs = [
        _pr(number=30),
        _pr(number=10),
        _pr(number=20, title="docs: x"),          # excluded
        _pr(number=40, cross=False),              # excluded
    ]
    assert fa.select(prs) == [10, 30]
    assert fa.select(prs, limit=1) == [10]
    assert fa.select(prs, limit=0) == []


def test_cli_reads_stdin(monkeypatch):
    prs = [_pr(number=7), _pr(number=8, title="chore: x")]
    monkeypatch.setattr("sys.stdin", io.StringIO(json.dumps(prs)))
    out = io.StringIO()
    monkeypatch.setattr("sys.stdout", out)
    assert fa.main(["select"]) == 0
    assert out.getvalue().split() == ["7"]


def test_cli_bad_json_is_empty(monkeypatch):
    monkeypatch.setattr("sys.stdin", io.StringIO("not json"))
    out = io.StringIO()
    monkeypatch.setattr("sys.stdout", out)
    assert fa.main(["select"]) == 0
    assert out.getvalue().strip() == ""


def test_cli_usage_without_subcommand():
    assert fa.main([]) == 2
