from tools.repo.pr_admission import DEFAULT_CUTOVER, decide


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
