"""Tests for batch verification selection/dedup/recovery (ADR-107, D1b)."""
from __future__ import annotations

import io
import json

import pytest

from tools.dispatch import batch as batchmod
from tools.dispatch.batch import (
    BATCH_TITLE_PREFIX,
    batch_branch_name,
    goal_of,
    main,
    manifest_block,
    open_batch_goals,
    parse_manifest,
    recover_action,
    select_batch,
)


# --- goal_of ----------------------------------------------------------------

def test_goal_of_strips_prefixes_and_agent_suffix():
    assert goal_of("origin/queued/prove/gself-pow-nine/mac-158f-4d5146") == "gself-pow-nine"
    assert goal_of("queued/prove/imo-1969-p2/claude-web-abc123") == "imo-1969-p2"


# --- select_batch -----------------------------------------------------------

def _refs(*goals):
    return [f"origin/queued/prove/{g}/agent-{i}" for i, g in enumerate(goals)]


def _disjoint_files(refs):
    # each ref adds its own goal-named files (the real content-addressed layout)
    return {r: {f"library/Unsorry/{goal_of(r)}.lean", f"goals/{goal_of(r)}.lean"} for r in refs}


def test_select_batch_picks_up_to_max_in_order():
    refs = _refs("a", "b", "c", "d")
    picked = select_batch(refs, _disjoint_files(refs), 3)
    assert [goal_of(r) for r in picked] == ["a", "b", "c"]


def test_select_batch_disabled_when_max_below_two():
    refs = _refs("a", "b")
    assert select_batch(refs, _disjoint_files(refs), 1) == []
    assert select_batch(refs, _disjoint_files(refs), 0) == []


def test_select_batch_excludes_named_goals():
    refs = _refs("a", "b", "c")
    picked = select_batch(refs, _disjoint_files(refs), 5, exclude_goals={"b"})
    assert [goal_of(r) for r in picked] == ["a", "c"]


def test_select_batch_skips_duplicate_goals():
    refs = _refs("a", "a", "b")  # two branches for goal a
    picked = select_batch(refs, _disjoint_files(refs), 5)
    assert [goal_of(r) for r in picked] == ["a", "b"]


def test_select_batch_skips_unknown_diff():
    refs = _refs("a", "b")
    files = _disjoint_files(refs)
    files[refs[0]] = []  # unknown / empty diff
    picked = select_batch(refs, files, 5)
    assert [goal_of(r) for r in picked] == ["b"]


def test_select_batch_drops_file_colliding_branch():
    # two branches that (anomalously) touch the SAME path must not co-batch
    refs = _refs("a", "b", "c")
    files = _disjoint_files(refs)
    files[refs[1]] = {"library/Unsorry/a.lean"}  # collides with ref a
    picked = select_batch(refs, files, 5)
    assert [goal_of(r) for r in picked] == ["a", "c"]


def test_select_batch_order_is_priority_order_in():
    # refs come pre-ordered (ADR-075/106); batch must preserve that order
    refs = _refs("hard1", "hard2", "template1")
    picked = select_batch(refs, _disjoint_files(refs), 2)
    assert [goal_of(r) for r in picked] == ["hard1", "hard2"]


# --- batch_branch_name ------------------------------------------------------

def test_batch_branch_name_deterministic_and_order_independent():
    assert batch_branch_name(["a", "b", "c"]) == batch_branch_name(["c", "b", "a"])
    assert batch_branch_name(["a", "b", "c"]).startswith("batch/prove/")


def test_batch_branch_name_distinct_for_distinct_sets():
    assert batch_branch_name(["a", "b"]) != batch_branch_name(["a", "c"])


# --- manifest round-trip ----------------------------------------------------

def test_manifest_block_parse_round_trip():
    goals = ["imo-1969-p2", "gself-pow-nine", "putnam-2020-b6"]
    body = "Some PR body.\n\n" + manifest_block(goals) + "\n\nfooter"
    assert sorted(parse_manifest(body)) == sorted(goals)


def test_parse_manifest_absent_or_empty():
    assert parse_manifest("") == []
    assert parse_manifest("no manifest here") == []
    assert parse_manifest(None) == []


def test_open_batch_goals_unions_only_batch_prs():
    prs = [
        {"title": "prove(solo-goal): x", "body": manifest_block(["solo-goal"])},  # not a batch
        {"title": BATCH_TITLE_PREFIX + "3): ...", "body": manifest_block(["g1", "g2"])},
        {"title": BATCH_TITLE_PREFIX + "2): ...", "body": manifest_block(["g3"])},
    ]
    assert sorted(open_batch_goals(prs)) == ["g1", "g2", "g3"]


# --- recover_action ---------------------------------------------------------

def test_recover_action_green_or_running_is_none():
    assert recover_action("success", []) == "none"
    assert recover_action("", []) == "none"
    assert recover_action(None, []) == "none"


def test_recover_action_cancelled_conclusion_reruns():
    assert recover_action("cancelled", []) == "rerun"


def test_recover_action_cancellation_cascade_reruns():
    # gate-a failed only because a shard was cancelled and the cover cascaded
    # (real job names per gate-a.yml: hyphenated, cover ends in -cover)
    jobs = [
        {"name": "gate-a-replay (3)", "conclusion": "cancelled"},
        {"name": "gate-a-replay-cover", "conclusion": "failure"},  # cascade (-cover)
        {"name": "gate-a", "conclusion": "failure"},               # cascade (aggregator)
    ]
    assert recover_action("failure", jobs) == "rerun"


def test_recover_action_genuine_failure_redispatches():
    jobs = [
        {"name": "gate-a-replay (2)", "conclusion": "failure"},  # genuine leaf failure
        {"name": "gate-a", "conclusion": "failure"},
    ]
    assert recover_action("failure", jobs) == "redispatch"


def test_recover_action_timed_out_genuine_redispatches():
    assert recover_action("timed_out", []) == "redispatch"


# --- CLI (main) contract ----------------------------------------------------

def test_cli_parse_manifest(monkeypatch, capsys):
    monkeypatch.setattr("sys.stdin", io.StringIO("intro\n\nBatch-Goals: g1 g2 g3\n\nfoot"))
    assert main(["parse-manifest"]) == 0
    assert capsys.readouterr().out.split() == ["g1", "g2", "g3"]


def test_cli_manifest_goals_batch_only(monkeypatch, capsys):
    prs = [
        {"title": "prove(s): x", "body": manifest_block(["s"])},
        {"title": BATCH_TITLE_PREFIX + "2): z", "body": manifest_block(["ga", "gb"])},
    ]
    monkeypatch.setattr("sys.stdin", io.StringIO(json.dumps(prs)))
    assert main(["manifest-goals"]) == 0
    assert sorted(capsys.readouterr().out.split()) == ["ga", "gb"]


@pytest.mark.parametrize("conclusion,jobs,expected", [
    ("success", [], "none"),
    ("failure", [{"name": "gate-a-replay (1)", "conclusion": "failure"}], "redispatch"),
    ("failure", [{"name": "gate-a-replay (1)", "conclusion": "cancelled"},
                 {"name": "gate-a", "conclusion": "failure"}], "rerun"),
])
def test_cli_recover(monkeypatch, capsys, conclusion, jobs, expected):
    monkeypatch.setattr("sys.stdin", io.StringIO(json.dumps(jobs)))
    assert main(["recover", "--conclusion", conclusion]) == 0
    assert capsys.readouterr().out.strip() == expected


def test_cli_meta_emits_branch_then_manifest(monkeypatch, capsys):
    refs = "origin/queued/prove/b/a-1\norigin/queued/prove/a/a-2\n"
    monkeypatch.setattr("sys.stdin", io.StringIO(refs))
    assert main(["meta"]) == 0
    out = capsys.readouterr().out.splitlines()
    assert out[0] == batchmod.batch_branch_name(["a", "b"])
    assert out[1] == manifest_block(["a", "b"])


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
