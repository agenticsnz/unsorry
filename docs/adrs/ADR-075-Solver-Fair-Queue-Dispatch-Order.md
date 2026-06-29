# ADR-075: Solver-Fair Queue Dispatch Order

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-075 |
| **Initiative** | unsorry — volunteer-scale orchestration / queue fairness |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-20 |
| **Status** | Accepted |

## Context

The queued-proof dispatcher (`dispatch_queue` in `swarm/agent.sh`, ADR-058) turns
`queued/prove/<goal>/<agent-id>-<hex>` branches into governed, auto-merge PRs. It
iterates `git for-each-ref refs/remotes/origin/queued/prove`, which returns refs
**lexically by name — i.e. by goal**. The submission governor (ADR-058) admits only a
few branches per pass and Gate A is the throughput ceiling (~1 h/proof, ≤20 in flight),
so dispatch effectively walks the goal alphabet a slice at a time. There is **no
per-solver fairness** in that walk.

The consequence is contributor starvation by lexical position. Observed in practice:
@ohdearquant and @chat-bit-01 between them hold ~1,882 `g…`-prefixed machine-named
goals (`geud-*`, `gzmod-*`) that sort to the very front; @ruvnet's 135 re-routed proofs
(the #1904 "ruv sledgehammer" recovery) cluster in `h…`/`s…` (103 of 135 start with
`s`) and sat at dispatch ranks **1850–2002 of 2003** — 0 in the first 600, 0 in-flight,
0 landed — while @ohdearquant's drained steadily. @ruvnet's backlog was verified
distinct, unproved, dup-free and self-contained: it was not blocked on admission,
dedup, or a build problem, only on **where its goal names fall in the alphabet**.

The ADR-054 open-PR quota caps the *top* of the queue per author (≤20 simultaneous open
prove PRs) but says nothing about drain *order*, so a late-sorting or lower-volume
contributor starves indefinitely behind a high-volume early-alphabet one.

## WH(Y) Decision Statement

**In the context of** a governed dispatcher that opens only a few queued proof PRs per
pass and walks branches in lexical (goal-name) order,

**facing** the choice between leaving dispatch lexical (a high-volume, early-alphabet
contributor starves everyone whose goals sort later — the observed @ruvnet case),
keying fairness on the branch commit author (wrong: a re-routed branch is authored by
the operator who ran `reroute_stranded`, not by the solver, so author-keying would
misattribute @ruvnet's 132 re-routes to the operator), or resolving solver provenance
per branch *inside* the dispatch loop (correct but reads every branch's index file
each pass — too slow for ~2,900 branches),

**we decided for** a **per-solver round-robin** ordering. `fair_dispatch_order` groups
the queued branches by solver — read from the authoritative queue board
(`docs/queue.json` on `origin/main`, which already resolves the `solver≜` /
git-author provenance, ADR-066) — and emits **one branch per solver per round**
(max-min fairness), with two graceful fallbacks: a branch not yet on the board (pushed
since the last board refresh) is bucketed by its **agent-id token**, and an unreadable
board degrades to the prior **lexical** order. Dedup (ADR-064/071), the governor
(ADR-058) and Gate A are unchanged — this only reorders the candidate list,

**and neglected** a per-branch provenance resolve in the loop (too slow), an
author-keyed grouping (misattributes re-routes), and a new persistent fair-queue
scheduler (an operational dependency ADR-004 deliberately avoids — the board already
carries the solver mapping, so no new state is introduced),

**to achieve** steady drain for **every active solver**: a small backlog (@ruvnet's
135) clears promptly instead of waiting behind ~1,900 earlier-sorting goals, while a
large backlog drains at the same per-round rate rather than monopolising every slot,

**accepting that** fairness is **best-effort ordering only** — it depends on a
generated artifact that can lag (a just-pushed branch is bucketed by agent-id token
until the next board refresh), the agent-id token is a coarse key that is gameable in
principle (bounded in practice by the ADR-054 per-author open-PR cap), and round-robin
**equalises per-round throughput across solvers rather than weighting by backlog
size** — a deliberate anti-starvation choice, not proportional sharing.

## Consequences

- **Soundness unchanged.** `fair_dispatch_order` only reorders the branch list the
  dispatcher already iterates. What merges is still decided by dedup, the governor, and
  Gate A's from-scratch kernel re-verification. The fairness layer is never
  trust-bearing; a wrong or empty ordering can at worst dispatch in the old order.
- **No new infrastructure or state** (ADR-004): the solver→branch mapping is read from
  the existing board; nothing is written, no queue server is introduced.
- **Reversible by env knob.** `UNSORRY_FAIR_DISPATCH=0` restores the exact prior lexical
  behaviour with no code change, for incident response or A/B comparison.
- **Complements, does not replace, ADR-054.** The quota bounds how much one author can
  occupy at the top of the queue; this bounds how the remaining capacity is *shared*
  across solvers as it drains.
- The immediate @ruvnet backlog is being relieved out-of-band by operator dispatch
  while this lands; this ADR is the durable fix so manual prioritisation is not needed
  again.
