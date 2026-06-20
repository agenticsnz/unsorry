from tools.repo import doctor


def test_422_means_token_can_open_prs():
    # 422 = GitHub reached request validation, so the token is authorized.
    c = doctor.classify_pr_permission(422, "Validation Failed: head is required")
    assert c.level == doctor.OK
    assert c.name == "pr-token"


def test_403_is_the_missing_pr_write_failure():
    # The exact production failure: REFRESH_TOKEN without pull-request-write.
    c = doctor.classify_pr_permission(
        403, "Resource not accessible by personal access token (createPullRequest) (HTTP 403)")
    assert c.level == doctor.FAIL
    assert "Pull requests: write" in c.detail or "repo" in c.detail


def test_401_invalid_token_fails():
    assert doctor.classify_pr_permission(401, "Bad credentials").level == doctor.FAIL


def test_404_no_repo_access_fails():
    assert doctor.classify_pr_permission(404, "Not Found").level == doctor.FAIL


def test_unexpected_success_warns_not_fails():
    # Never FAIL on an inconclusive result — a probe glitch must not block ops.
    assert doctor.classify_pr_permission(0, "").level == doctor.WARN


def test_unknown_status_warns():
    assert doctor.classify_pr_permission(500, "server error").level == doctor.WARN


def test_parse_http_status_from_gh_error():
    assert doctor.parse_http_status(
        1, "gh: Resource not accessible by personal access token (HTTP 403)") == 403


def test_parse_http_status_clean_exit_is_zero():
    assert doctor.parse_http_status(0, '{"number": 1}') == 0


def test_parse_http_status_error_without_marker_is_negative():
    assert doctor.parse_http_status(1, "network unreachable") == -1


def test_main_returns_nonzero_on_fail(monkeypatch, capsys):
    # A FAIL check must make the command exit non-zero so CI fails fast.
    monkeypatch.setitem(doctor.CHECKS, "pr-token",
                        lambda repo: doctor.Check("pr-token", doctor.FAIL, "nope"))
    rc = doctor.main(["--repo", "owner/name", "--check", "pr-token"])
    assert rc == 1
    assert "FAIL" in capsys.readouterr().out


def test_main_returns_zero_when_ok(monkeypatch):
    monkeypatch.setitem(doctor.CHECKS, "pr-token",
                        lambda repo: doctor.Check("pr-token", doctor.OK, "fine"))
    assert doctor.main(["--repo", "owner/name", "--check", "pr-token"]) == 0
