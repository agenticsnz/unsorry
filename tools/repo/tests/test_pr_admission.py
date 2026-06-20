from tools.repo.pr_admission import (
    DEFAULT_CUTOVER,
    DEFAULT_MAX_OPEN_PROVE_PRS_PER_AUTHOR,
    decide,
    quota_decide,
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
