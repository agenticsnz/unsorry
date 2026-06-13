# ADR-029: Harness Commit Authorship from GitHub Identity

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-029 |
| **Initiative** | swarm harness / proof provenance |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-13 |
| **Status** | Accepted |

## WH(Y) Decision Statement
**In the context of** a distributed swarm where any operator — increasingly a "normal user" on a freshly provisioned machine — runs `swarm/agent.sh` to commit and push verified proofs, claims, and telemetry under their own GitHub account,
**facing** the fact that the harness commits with `git commit` using the operator's *ambient* git config, which on a fresh machine is git's `Your Name <you@example.com>` placeholder; GitHub cannot link such a commit to any profile, so verified work shows as authored by a non-existent identity even though the AISP `solver≜` field (read from `gh api user`) is correct — the contributor is mis-credited at the git layer, and the failure is silent and provider-independent (observed on a gemini run, but identical for every provider),
**we decided for** a `resolve_git_identity` resolver that, in the proof path, derives the commit author/committer from the authenticated GitHub account — the display name (falling back to the login) and the no-reply email `<id>+<login>@users.noreply.github.com` — and exports it through git's own `GIT_AUTHOR_*`/`GIT_COMMITTER_*` variables so every subsequent harness `git commit` inherits it with no per-call-site change; `UNSORRY_SOLVER_NAME`/`UNSORRY_SOLVER_EMAIL` override the derived values, and when no identity is resolvable (offline, no override) it fails soft to the local git config rather than blocking a proof,
**and neglected** rewriting the operator's `~/.gitconfig` (invasive, surprising, and affects unrelated repos), pinning the author with a `--author` flag on each `git commit` call site (more edits, easy to miss a new commit later, and does not set the committer), and constructing the email from the login alone (the numeric `id` is required for the stable no-reply address, so a single `gh api user` call fetches login+id+name together),
**to achieve** that verified proofs and coordination commits link to the contributor's real GitHub profile out of the box, regardless of local git configuration, so attribution "just works" for normal users,
**accepting that** the no-reply email links only when GitHub email-privacy semantics hold (always true for the `<id>+<login>` form), that the git author may differ from `UNSORRY_SOLVER` when that credit label is overridden to a third party (the author reflects who actually pushes; the `solver≜` field reflects credit — intentionally decoupled), and that the resolver applies only to the harness's own commits, never to the operator's manual commits.

## References
| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Harness commit-authorship specification | Specification | specs/SPEC-029-A-Harness-Commit-Authorship.md |
| REF-2 | Proof provenance and leaderboard | Decision | ADR-023-Proof-Provenance-Leaderboard.md |
| REF-3 | GitHub no-reply email addresses | Reference | https://docs.github.com/en/account-and-profile/setting-up-and-managing-your-personal-account-on-github/managing-email-preferences/setting-your-commit-email-address |

## Status History
| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-13 |
| Accepted | unsorry maintainers | 2026-06-13 |
