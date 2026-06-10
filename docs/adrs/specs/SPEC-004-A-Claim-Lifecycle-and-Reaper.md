# SPEC-004-A: Claim Lifecycle and Reaper

Implements: [ADR-004](../ADR-004-Claims-Branch-First-Push-Wins.md) · Status: Living · Updated: 2026-06-10

## Lifecycle

```
            push claims/<goal>.<agent>.aisp → claims branch
   ┌─────────┐  push accepted   ┌──────┐  work done   ┌──────────┐
   │ unclaimed├────────────────→│ live │─────────────→│ released │ (agent rm + push)
   └─────────┘                  └──┬───┘              └──────────┘
        ↑    push rejected →       │ now > ts+ttl
        │    rebase; competing     ↓
        │    claim? → collision,   ┌─────────┐
        └────select next goal      │ expired │→ reaped by cron (rm + push)
                                   └─────────┘
```

- **Claim**: `git fetch origin claims` → write file → commit → `git push origin HEAD:claims`. A rejected (non-fast-forward) push means the branch moved: `git pull --rebase`; if a competing claim for the same goal now exists, log a collision event and select another goal; otherwise push again.
- **Release**: the claiming agent removes its own claim file and pushes (on success after merge, or on giving up).
- **Reap**: expired claims (`now > ts + ttl`) are removed by the scheduled reaper.

## Reaper (`tools/gate_b/reaper.py`)

- Runs from the same package as the validator and **shares its TTL/claim-parsing logic** (DRY — one implementation of "is this claim expired").
- CLI: `python -m tools.gate_b.reaper <claims-root> [--at ISO8601] [--dry-run] [--json]`. Exit 0 (nothing to reap or reaped OK), 1 (violations encountered), 2 (internal error).
- Scheduled workflow `reaper.yml`: cron every 15 min (`*/15 * * * *`), checks out the `claims` branch, runs the reaper, commits removals with message `reap: <n> expired claim(s)`, pushes. Reaped claim filenames + ages are written to the GitHub Actions run summary — this is the durable evidence trail for readiness-checklist item (c) (TTL reaping observed).
- GitHub cron is best-effort (minutes of drift): TTL (7200 s) ≥ 4× interval (900 s) guarantees drift cannot cause premature reaps. The reaper never reaps a live claim; `--at` injects the clock in tests.
- Concurrency guard: the workflow uses `concurrency: reaper` so two scheduled runs cannot race each other's push; on push rejection the run rebases once and retries, then gives up (next cron gets it).

## Acceptance criteria (PR-4 tests)

1. With `--at` before expiry: zero files removed (`--dry-run` and real mode agree).
2. With `--at` after expiry: exactly the expired claims are removed; live ones untouched.
3. Reaper and validator return identical expiry verdicts for every fixture claim (shared logic, asserted by test).
4. `--dry-run --json` output is deterministic and lists relative paths + ages.
