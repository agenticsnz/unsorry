import json

from tools.repo.pr_admission import (
    DEFAULT_CUTOVER,
    DEFAULT_MAX_OPEN_PROVE_PRS_PER_AUTHOR,
    decide,
    quota_decide,
    resolve_is_fork,
)


def test_quota_under_cap_is_admitted() -> None:
    assert quota_decide(5, cap=20).admitted
    assert quota_decide(0, cap=20).admitted


def test_quota_at_cap_is_admitted() -> None:
    # The cap is inclusive: holding exactly `cap` open PRs is allowed.
    assert quota_decide(20, cap=20).admitted


def test_quota_over_cap_is_rejected() -> None:
    verdict = quota_decide(21, cap=20)
    assert not verdict.admitted
    assert "over the per-contributor cap" in verdict.reason


def test_quota_far_over_cap_is_rejected() -> None:
    # The monopolisation case: 43 open PRs from one author.
    assert not quota_decide(43, cap=20).admitted


def test_quota_default_cap_is_twenty() -> None:
    assert DEFAULT_MAX_OPEN_PROVE_PRS_PER_AUTHOR == 20
    assert quota_decide(20).admitted
    assert not quota_decide(21).admitted


def test_push_or_non_pr_event_is_admitted() -> None:
    verdict = decide("", "", "")
    assert verdict.admitted


def test_existing_direct_pr_before_cutover_is_admitted() -> None:
    verdict = decide(
        "2026-06-16T22:24:43Z",
        "feature/goal-sum-example-pr-agent",
        "prove(sum-example): sum_example by agent",
        DEFAULT_CUTOVER,
    )
    assert verdict.admitted


def test_new_direct_feature_goal_pr_after_cutover_is_rejected() -> None:
    verdict = decide(
        "2026-06-16T22:24:44Z",
        "feature/goal-sum-example-pr-agent",
        "prove(sum-example): sum_example by agent",
        DEFAULT_CUTOVER,
    )
    assert not verdict.admitted


def test_new_direct_prove_branch_after_cutover_is_rejected() -> None:
    verdict = decide(
        "2026-06-16T22:30:00Z",
        "prove/sum-example-agent",
        "prove(sum-example): sum_example by agent",
        DEFAULT_CUTOVER,
    )
    assert not verdict.admitted


def test_dispatcher_queue_branch_after_cutover_is_admitted() -> None:
    verdict = decide(
        "2026-06-16T22:30:00Z",
        "queued/prove/sum-example/agent-123abc",
        "prove(sum-example): sum_example by agent",
        DEFAULT_CUTOVER,
    )
    assert verdict.admitted


def test_non_proof_maintenance_pr_after_cutover_is_admitted() -> None:
    verdict = decide(
        "2026-06-16T22:30:00Z",
        "ci/pr-admission-control",
        "ci: add proof admission control",
        DEFAULT_CUTOVER,
    )
    assert verdict.admitted


def test_unblock_coordination_pr_after_cutover_is_admitted() -> None:
    # ADR-009 unblock PR on a feature/goal-* branch — title is unblock(...), not
    # prove(...), so it must NOT be auto-closed as a direct proof (issue #3128).
    verdict = decide(
        "2026-06-16T22:30:00Z",
        "feature/goal-sum-icc-choose-hockey-stick-unblock-beast-dddd-427102",
        "unblock(sum-icc-choose-hockey-stick): sub-lemmas proved",
        DEFAULT_CUTOVER,
    )
    assert verdict.admitted


def test_decompose_coordination_pr_after_cutover_is_admitted() -> None:
    verdict = decide(
        "2026-06-16T22:30:00Z",
        "feature/goal-sq-add-sq-eq-three-mul-sq-s4-decompose-agent-abc123",
        "decompose(sq-add-sq-eq-three-mul-sq-s4): 3 sub-lemmas",
        DEFAULT_CUTOVER,
    )
    assert verdict.admitted


# --- ADR-068: fork-native cross-repo proof PRs --------------------------------


def test_fork_direct_prove_after_cutover_is_admitted() -> None:
    # A fork-native cross-repo proof PR (e.g. PR #3187 by Rauxon) is direct only
    # because queued/prove/* is upstream-only and inaccessible to forks. With
    # is_fork=True it is admitted past the cutover (ADR-068); Gate A still
    # re-verifies. Mirrors the same inputs that test_new_direct_prove_branch_
    # after_cutover_is_rejected blocks for a same-repo PR.
    verdict = decide(
        "2026-06-16T22:30:00Z",
        "prove/sum-example-agent",
        "prove(sum-example): sum_example by agent",
        DEFAULT_CUTOVER,
        is_fork=True,
    )
    assert verdict.admitted
    assert "ADR-068" in verdict.reason


def test_fork_direct_feature_goal_prove_after_cutover_is_admitted() -> None:
    verdict = decide(
        "2026-06-16T22:24:44Z",
        "feature/goal-sum-example-pr-agent",
        "prove(sum-example): sum_example by agent",
        DEFAULT_CUTOVER,
        is_fork=True,
    )
    assert verdict.admitted


def test_same_repo_direct_prove_after_cutover_still_rejected() -> None:
    # is_fork defaults to False: same-repo direct submits stay blocked post-cutover
    # so the fork exemption cannot be used to bypass the queue from inside the repo.
    verdict = decide(
        "2026-06-16T22:30:00Z",
        "prove/sum-example-agent",
        "prove(sum-example): sum_example by agent",
        DEFAULT_CUTOVER,
        is_fork=False,
    )
    assert not verdict.admitted


def test_fork_flag_does_not_admit_non_proof_or_pre_cutover_unchanged() -> None:
    # is_fork only matters when the PR would otherwise be blocked by the cutover;
    # other verdicts are unchanged (non-proof admitted, pre-cutover admitted).
    assert decide(
        "2026-06-16T22:30:00Z", "ci/x", "ci: tweak", DEFAULT_CUTOVER, is_fork=True
    ).admitted
    assert decide(
        "2026-06-16T22:24:43Z",
        "prove/x",
        "prove(x): x",
        DEFAULT_CUTOVER,
        is_fork=True,
    ).admitted


def _write_event(tmp_path, head_full_name) -> str:
    payload = {"pull_request": {"head": {"repo": {"full_name": head_full_name}}}}
    path = tmp_path / "event.json"
    path.write_text(json.dumps(payload), encoding="utf-8")
    return str(path)


def test_resolve_is_fork_cross_repo_is_true(tmp_path) -> None:
    event = _write_event(tmp_path, "Rauxon/unsorry")
    assert resolve_is_fork(event, "agenticsnz/unsorry") is True


def test_resolve_is_fork_same_repo_is_false(tmp_path) -> None:
    event = _write_event(tmp_path, "agenticsnz/unsorry")
    assert resolve_is_fork(event, "agenticsnz/unsorry") is False


def test_resolve_is_fork_missing_event_path_is_false() -> None:
    assert resolve_is_fork("", "agenticsnz/unsorry") is False
    assert resolve_is_fork("/nonexistent/path/event.json", "agenticsnz/unsorry") is False


def test_resolve_is_fork_missing_repository_is_false(tmp_path) -> None:
    event = _write_event(tmp_path, "Rauxon/unsorry")
    assert resolve_is_fork(event, "") is False


def test_resolve_is_fork_null_head_repo_is_false(tmp_path) -> None:
    # Same-repo PR events can carry head.repo == null; treat as same-repo.
    path = tmp_path / "event.json"
    path.write_text(
        json.dumps({"pull_request": {"head": {"repo": None}}}), encoding="utf-8"
    )
    assert resolve_is_fork(str(path), "agenticsnz/unsorry") is False


def test_resolve_is_fork_malformed_json_is_false(tmp_path) -> None:
    path = tmp_path / "event.json"
    path.write_text("{not json", encoding="utf-8")
    assert resolve_is_fork(str(path), "agenticsnz/unsorry") is False


def test_resolve_is_fork_reads_env(tmp_path, monkeypatch) -> None:
    event = _write_event(tmp_path, "Rauxon/unsorry")
    monkeypatch.setenv("GITHUB_EVENT_PATH", event)
    monkeypatch.setenv("GITHUB_REPOSITORY", "agenticsnz/unsorry")
    assert resolve_is_fork() is True
    monkeypatch.setenv("GITHUB_REPOSITORY", "Rauxon/unsorry")
    assert resolve_is_fork() is False
