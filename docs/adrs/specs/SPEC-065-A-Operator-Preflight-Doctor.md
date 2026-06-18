# SPEC-065-A: Operator Preflight Doctor

Implements: [ADR-065](../ADR-065-Operator-Preflight-Doctor.md) | Status: Accepted | Updated: 2026-06-17

Defines `tools/repo/doctor.py` — operator preflight health checks.

## 1. CLI

```
python3 -m tools.repo.doctor [--repo owner/name] [--check NAME ...] [--json]
```

- `--repo` defaults to `$GITHUB_REPOSITORY`; required if unset.
- `--check` selects checks by name (repeatable); default runs all.
- `--json` emits a JSON array of `{name, level, detail}`; otherwise one line per
  check (`✓/!/✗ [LEVEL] name: detail`).
- Exit code: **1** if any check is `FAIL`, else **0**. (`WARN` does not fail.)

## 2. Check levels

`OK` (precondition satisfied) · `WARN` (inconclusive — never blocks) · `FAIL`
(precondition violated — exit non-zero).

## 3. `pr-token` check

Verifies the active token (ambient `gh` auth / `GH_TOKEN`) can open pull requests.

Probe: `gh api -X POST repos/<repo>/pulls -f title=unsorry-doctor-preflight` with
**no `head`/`base`**. No PR can be created (those fields are required), so this is
side-effect-free. GitHub authorizes the token before validating the body, so:

| HTTP status | Meaning | Level |
|---|---|---|
| 422 | reached request validation → token **is** authorized | `OK` |
| 401 | invalid/expired token | `FAIL` |
| 403 | not authorized to create PRs (missing `Pull requests: write` / `repo`) | `FAIL` |
| 404 | no repo access / wrong `--repo` | `FAIL` |
| 0 (clean exit) | unexpected success — verify no stray PR | `WARN` |
| other | inconclusive | `WARN` |

`classify_pr_permission(status, message)` (the table) and
`parse_http_status(returncode, output)` (extracts `(HTTP NNN)` from `gh` output;
clean exit → 0; error without marker → -1) are pure and unit-tested. The default
on any unrecognized status is `WARN`, never a false `OK`.

## 4. Extensibility

Checks live in the `CHECKS` registry (`name -> callable(repo) -> Check`). Future
operator checks (Namespace runner capacity, last queue-dispatcher run result,
settings drift — ADR-051/056) register here without changing the CLI.

## 5. Integration

`.github/workflows/queue-dispatcher.yml` runs `--check pr-token` after
checkout/setup-python and **before** the dispatch step, with
`GH_TOKEN=${{ secrets.REFRESH_TOKEN }}`. A `FAIL` fails the job in one step with a
fix-it message, instead of attempting a full dispatch pass that errors per branch.

## 6. Out of scope

- The full ADR-051/056 dashboard and operator action surface.
- Checks beyond `pr-token` (registered incrementally).
