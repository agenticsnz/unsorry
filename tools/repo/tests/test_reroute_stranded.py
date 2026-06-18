"""Tests for the stranded-proof re-route helpers (ADR-058 recovery)."""
import pytest

from tools.repo.reroute_stranded import (
    is_proof_file,
    parse_prove_title,
    queued_branch,
)


@pytest.mark.parametrize(
    "path,expected",
    [
        ("library/Unsorry/SumRangeFoo.lean", True),
        ("library/index/abc123.aisp", True),
        ("goals/sum-range-foo.aisp", True),
        ("proof-runs/sum-range-foo.agent.run.aisp", True),
        # not proof-tree files:
        ("goals/sum-range-foo.lean", False),       # immutable statement, never re-routed
        ("library/Unsorry/SumRangeFooBinding.lean", True),  # still a Unsorry/*.lean (Gate B would reject if bogus)
        ("docs/leaderboard.md", False),
        ("README.md", False),
        ("library/index/abc123.txt", False),
    ],
)
def test_is_proof_file(path, expected):
    assert is_proof_file(path) is expected


def test_queued_branch_is_admitted_shape():
    b = queued_branch("sum-range-foo", "a1b2c3")
    assert b == "queued/prove/sum-range-foo/reroute-a1b2c3"
    assert b.startswith("queued/prove/")  # pr_admission admits this prefix


def test_parse_prove_title_with_by():
    goal, name = parse_prove_title("prove(sum-range-foo): sum_range_foo by ruvnet")
    assert goal == "sum-range-foo"
    assert name == "sum_range_foo"


def test_parse_prove_title_without_by():
    goal, name = parse_prove_title("prove(nat-zero-lt-succ): nat_zero_lt_succ")
    assert goal == "nat-zero-lt-succ"
    assert name == "nat_zero_lt_succ"


def test_parse_prove_title_rejects_non_prove():
    for bad in ("docs: refresh", "unblock(foo): re-opening", "feat: thing", ""):
        with pytest.raises(ValueError):
            parse_prove_title(bad)
