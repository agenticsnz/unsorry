# SPEC-029-A: Harness Commit Authorship from GitHub Identity

Implements: [ADR-029](../ADR-029-Harness-Commit-Authorship.md) · Status: Living · Updated: 2026-06-13

## Resolver

`resolve_git_identity` (in `swarm/agent.sh`) resolves a git author/committer
identity for the harness's own commits:

1. If both `UNSORRY_SOLVER_NAME` and `UNSORRY_SOLVER_EMAIL` are set, use them
   verbatim and make no network call.
2. Otherwise call `gh api user` once, reading `login`, `id`, and `name` as a
   single tab-separated row (`[.login, (.id|tostring), (.name // "")] | @tsv`):
   - **email** ← `UNSORRY_SOLVER_EMAIL` if set, else the GitHub no-reply address
     `<id>+<login>@users.noreply.github.com`;
   - **name** ← `UNSORRY_SOLVER_NAME` if set, else the account display name,
     falling back to the `login` when the account has no name.
3. If, after that, either name or email is still empty (offline, unauthenticated,
   no override), log a warning and return success without exporting anything —
   the commit then uses the operator's local git config. Attribution is
   best-effort and never blocks a proof.

When a name and email are resolved, the resolver exports all four of
`GIT_AUTHOR_NAME`, `GIT_AUTHOR_EMAIL`, `GIT_COMMITTER_NAME`, and
`GIT_COMMITTER_EMAIL`. Because these are git's native environment variables,
every later `git commit` the harness runs (proof PRs via `submit_pr_tree`,
claim and release commits, failed-run telemetry) inherits the identity without
touching any individual call site.

## Invocation

The resolver runs once in the proof path, immediately after `resolve_solver`,
guarded by `[ "$PROVE" -eq 1 ]` inside the non-dry-run setup block. It does not
run in `--prove-local` (which performs no commit and no remote operation) nor in
`--dry-run`.

## Relationship to `solver≜`

The resolved git author is independent of the AISP `solver≜` field. `solver≜`
records *credit* (`UNSORRY_SOLVER` or the authenticated login) and may name a
third party; the git author records *who actually authored the commit* (the
authenticated account, unless `UNSORRY_SOLVER_NAME`/`_EMAIL` override). Both
default to the same authenticated account, so the common case is consistent.

## Validation

`test_git_identity_resolution` (an `swarm/agent.sh --self-test` case) asserts,
with a mocked `gh`:

- the no-reply email and display name are derived from `login`/`id`/`name`, and
  committer identity matches author identity;
- an account with an empty `name` falls back to the `login`;
- explicit `UNSORRY_SOLVER_NAME`/`UNSORRY_SOLVER_EMAIL` overrides win and make
  no `gh` call.

The soft-fail path (no identity resolvable) leaves the four variables unset and
returns success, so existing commit behaviour is preserved when GitHub identity
is unavailable.
