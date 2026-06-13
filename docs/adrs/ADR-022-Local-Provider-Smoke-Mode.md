# ADR-022: Local Provider Smoke Mode

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-022 |
| **Initiative** | unsorry swarm provider portability |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-13 |
| **Status** | Accepted |

## WH(Y) Decision Statement
**In the context of** a swarm loop whose production path claims globally coordinated work and can autonomously open mergeable proof PRs,
**facing** the need to evaluate additional coding-agent CLIs without risking duplicate claims, queue penalties, remote branches, or GitHub noise while their tool and failure semantics are still unproven,
**we decided for** a `--prove-local [--goal <id>] --provider <name>` mode that reuses the production proof prompt and full local kernel verification in a preserved detached worktree from local `HEAD`, but exits before every remote and coordination operation; without `--goal` it automatically takes the highest-ranked open, unproved goal from local `HEAD`; provider execution is adapter-backed, Codex initially joins Claude, and a provider-independent git path guard rejects every edit outside the one target module,
**and neglected** switching the production swarm directly by environment variable (provider failures would become queue evidence before validation), a mock-only adapter test (it cannot establish that authentication, tools, Lean iteration, and sandboxing work together), and an unrestricted local agent run (it would not test the production write boundary),
**to achieve** an end-to-end provider trial with the same proof and soundness bar as production and zero remote side effects,
**accepting that** the local mode does not test claims or PR creation, that its worktree contains committed `HEAD` rather than uncommitted files, and that each provider still needs a live smoke before production enablement; after that trial, Codex is enabled for coordinated proving and provider-specific decomposition while Gemini and OpenAI remain local-only.

## References
| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Agent loop script | Specification | specs/SPEC-007-A-Agent-Loop-Script.md |

## Status History
| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-13 |
| Accepted | unsorry maintainers | 2026-06-13 |
