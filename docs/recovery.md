# Recovery: how stranded proofs get back into the pipeline

This document explains how the swarm submits proofs, why a submission can get
**stranded**, and the self-healing machinery that recovers stranded proofs
without losing work or re-proving anything. It is the operator's map for the
queued-proof flow and the [Gate A capacity](#capacity-the-real-bottleneck)
backstop.

## The submission model (the happy path)

A proving agent does **not** open a PR per proof. After it verifies a proof
locally, it pushes a `queued/prove/<goal>/<agent-id>-<hex>` branch (the default
`UNSORRY_SUBMIT_MODE=queue`) and stops. A separate **dispatcher** turns those
queued branches into PRs, rate-limited by a **submission governor** ([ADR-058],
[SPEC-007-A]):

```
agent --prove  ──▶  queued/prove/* branch        (locally verified, no PR yet)
                         │
        queue-dispatcher (scheduled, governor-metered)
                         │
                         ▼
                    gh pr create + auto-merge  ──▶  Gate A re-verifies  ──▶  merge
```

The dispatcher only **re-packages** an existing branch into a PR — it never
re-proves. **Gate A re-verifies every proof from scratch** under its pinned
toolchain, so nothing about soundness is trusted from the producer; the queue is
purely a throughput/ordering mechanism.

The governor ([ADR-058]) bounds how much verifier work is in flight:

| Knob | Default | Meaning |
|---|---|---|
| `UNSORRY_MAX_OPEN_PROVE_PRS` | 40 | Pause dispatch when this many open `prove(` PRs already exist. |
| `UNSORRY_MAX_GATE_A_IN_FLIGHT` | 20 | Pause dispatch when queued + in-progress Gate A runs reach this. |
| `UNSORRY_DISPATCH_LIMIT` | 1 (10 in the workflow) | Max branches dispatched per pass. |

So a flood of queued work drains **in order at Gate A's pace**, instead of
swamping the runners all at once.

## Why a proof gets stranded

Two failure modes put a valid proof outside the queue:

1. **Direct `prove(...)` submission after the cutover.** Before the queued
   dispatcher existed, agents opened proof PRs directly (`feature/goal-*`,
   `prove/*`, or a `prove(...)` title). Those are no longer accepted: repository
   admission control ([`tools/repo/pr_admission.py`](../tools/repo/pr_admission.py),
   `pr-admission` workflow) labels a post-cutover direct submission
   `blocked-direct-submit` and closes it.
2. **Pre-cutover direct submissions flooding Gate A.** Direct PRs opened *before*
   the cutover are let through to drain — but if hundreds arrive at once, their
   `gate-a-replay` / `gate-a-audit` jobs (≈1h each) queue indefinitely behind the
   runner cap, and the open-PR count parks the dispatcher's governor above its
   pause threshold. The result is a deadlock: the direct PRs never verify, and
   the governor stays paused so the queue never drains either. This is the
   [#1904] "ruv sledgehammer" case and the capacity issue [#1909].

## The recovery pipeline

Four pieces turn a stranded proof back into a landing one. No proof is ever
lost: closing a PR never deletes its branch or commits, and the recovered proof
is *copied* onto the queue before anything is closed.

### 1. Admission offers the re-route (self-heal)

When admission control closes a direct submission, its comment now offers the
re-route command (not just "re-prove"), so a contributor's direct-submission
campaign self-heals into the metered queue instead of stranding.

### 2. `reroute_stranded.py` — re-package without re-proving

[`tools/repo/reroute_stranded.py`](../tools/repo/reroute_stranded.py) copies a
stranded PR's proof files (`library/Unsorry/<Camel>.lean`,
`library/index/<sha>.aisp`, `goals/<goal>.aisp`) onto a fresh
`queued/prove/<goal>/reroute-<hex>` branch off the current `main`,
Gate-B-validates the tree, and pushes it:

```bash
python3 -m tools.repo.reroute_stranded --pr <n> --push
```

A self-contained proof (`import Mathlib`) re-routes cleanly; one that imports a
now-archived `Unsorry.*` module fails Gate A on dispatch — the safe outcome (it
genuinely no longer builds on current `main`).

### 3. `queue-dispatcher` — drain the queue automatically

The [`queue-dispatcher`](../.github/workflows/queue-dispatcher.yml) workflow runs
`swarm/agent.sh --dispatch-queue --once` every 15 minutes: it opens a
governor-metered PR for each queued branch and arms auto-merge, so the backlog
(including re-routed proofs) drains without an operator running the dispatcher by
hand. It self-throttles — it dispatches only while in-flight Gate A work is below
the cap and no-ops when full.

It authenticates with the admin `REFRESH_TOKEN` secret (a PR opened by the
default `GITHUB_TOKEN` does not trigger Gate A, so it could never merge); when
the secret is unset the job degrades to a report-only notice.

### 4. `close-superseded` — retire the stranded originals

[`tools/repo/close_superseded.py`](../tools/repo/close_superseded.py) and the
[`close-superseded`](../.github/workflows/close-superseded.yml) workflow close a
stranded direct PR **once its goal is proved on `main`** (i.e. its re-route, or a
peer, landed) — and **never** a PR whose goal is still open. So as the dispatcher
lands re-routed proofs, the superseded originals retire automatically and the
backlog shrinks instead of doubling.

```bash
python3 -m tools.repo.close_superseded [--author <login>] [--dry-run]
```

### The full loop

```
direct PR stranded ─▶ admission offers re-route ─▶ reroute_stranded.py ─▶ queued/prove/*
                                                                              │
                                              queue-dispatcher (15m, metered) │
                                                                              ▼
                                              PR ─▶ Gate A re-verifies ─▶ merge ─▶ goal proved
                                                                                      │
                                              close-superseded (hourly) ◀────────────┘
                                                  retires the stranded original
```

## Capacity: the real bottleneck

Re-routing and dispatching only **order** the work — they do not create verifier
capacity. The rate-limiting step is Gate A itself: `gate-a-replay` /
`gate-a-audit` take ≈1h, and the governor keeps ≤20 in flight, so a deep queue
drains over hours/days. The durable fix is verification throughput — more / larger
runners, or sharding the replay/audit pole — tracked in [#1909] ([ADR-058]
runner-pool segmentation). Per-agent submission quotas ([ADR-053]/[ADR-054]) are
the complementary lever so one agent cannot park hundreds of PRs at once.

## Operator quick reference

| Task | Command / setting |
|---|---|
| Enable the scheduled dispatcher | set the `REFRESH_TOKEN` secret (admin PAT/App) |
| Dispatch one pass by hand | `./swarm/agent.sh --dispatch-queue --once` |
| Re-route one stranded PR | `python3 -m tools.repo.reroute_stranded --pr <n> --push` |
| Close superseded originals | `python3 -m tools.repo.close_superseded [--author <l>] [--dry-run]` |
| Loosen / tighten the drain | `UNSORRY_DISPATCH_LIMIT`, `UNSORRY_MAX_OPEN_PROVE_PRS`, `UNSORRY_MAX_GATE_A_IN_FLIGHT` |
| Emergency pause | `UNSORRY_SUBMISSION_FREEZE=1` |

[ADR-058]: adrs/ADR-058-Runner-Pool-Segmentation-And-Verification-Capacity.md
[ADR-053]: adrs/ADR-053-Volunteer-Scale-Claim-Substrate.md
[ADR-054]: adrs/ADR-054-Agent-Identity-Quotas-And-Reputation.md
[SPEC-007-A]: adrs/specs/SPEC-007-A-Agent-Loop-Script.md
[#1904]: https://github.com/agenticsnz/unsorry/issues/1904
[#1909]: https://github.com/agenticsnz/unsorry/issues/1909
