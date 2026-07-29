# ADR-118: A Check-In Failure Is Not Evidence About the Goal

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-118 |
| **Initiative** | unsorry swarm reliability — irreversible-action safety |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-07-29 |
| **Status** | Accepted |

## Context

`prove_goal` runs two independent phases. `run_proof` generates a proof and verifies it —
built with `lake build --wfail` at the suite or repo pin, with an ADR-011 statement binding
proving it inhabits the goal's exact type. `check_in_proof` then submits that tree: Gate B
validation, commit, push, PR.

Only the first says anything about the goal. The second says something about the *tree* —
whether its coordination records are well-formed, whether the push won its race, whether the
PR could be opened. The two were nonetheless collapsed into one outcome:

```bash
run_proof … || prc=$?
if [ "$prc" -eq 0 ]; then
  if check_in_proof …; then ok=1; fi     # failure reason discarded here
fi
…
if [ "$prc" -eq 2 ]; then … return 2; fi  # ADR-016 infra: no penalty
emit_event prove-failed "$goal"           # everything else, including a verified proof
```

`prc=0` means the proof verified. When `check_in_proof` failed, `ok` stayed `0` and control
fell through to the prove-failed path — ADR-009 decompose-on-failure, then ADR-010/ADR-034
demote.

The consequence is irreversible. ADR-018 makes `goals/*.lean` **create-only**;
`gate-a-prepare` rejects deletions. So a submission-side hiccup mints sub-goals that can never
be removed, *and* discards a kernel-verified proof, *and* parks the parent `blocked`.

Observed twice on the same goal tree:

- **#7133** decomposed `aime-1983-p9-s1` into `-s1-s1`/`-s1-s2`. The revert attempt #7135 was
  closed as invalid precisely because ADR-018 forbids it; the extra depth is permanent.
- **#7151** proved `aime-1983-p9-s2` on attempt 1 at effort `high`, then discarded it because
  Gate B could not resolve an index written at the suite pin (#7158). The log is explicit that
  the proof was fine before the goal was decomposed:

  ```
  [agent.sh] proof of aime-1983-p9-s2 verified locally — statement bound (attempt 1)
  [agent.sh] queued tree on queued/prove/aime-1983-p9-s2/… fails Gate B — not pushing
  [agent.sh] prove of aime-1983-p9-s2 failed — decomposed into sub-lemmas, parent blocked (ADR-009)
  ```

  The resulting decompose PR opened with auto-merge armed and was mergeable within seconds; it
  was closed by hand before it landed.

#7158 removed that particular trigger. It did not remove the mechanism: **any** future Gate B
rejection of a valid proof tree does the same thing again, permanently, and Gate B is a moving
target by design — it gains rules.

Compounding it, both Gate B calls discarded the validator's output (`>/dev/null`), so the only
diagnostic was `fails Gate B`. Finding the #7158 cause required re-running the validator by hand
against a reconstructed tree.

ADR-016 already establishes the governing principle for the neighbouring case: when the provider
CLI never ran, that is zero evidence about the goal, so the claim is released with no event, no
decomposition and no demote. A check-in failure is the same class of event — arguably more so,
since here a *correct proof demonstrably exists*.

## WH(Y) Decision Statement

**In the context of** `prove_goal`, where `run_proof` decides whether a proof exists and
`check_in_proof` decides whether its tree can be submitted,
**facing** the collapse of those two outcomes into one, so a submission-side failure — a Gate B
rejection, a lost push race, a PR that would not open — routed a **kernel-verified proof** into
the ADR-009 decompose-on-failure path, discarding the proof and minting sub-goals that ADR-018
makes permanent (observed twice on `aime-1983-p9`, in #7133 and #7151), while the swallowed
validator output left `fails Gate B` as the only diagnostic,
**we decided for** treating a check-in failure that follows a successful `run_proof` as the
ADR-016 no-penalty class — no `prove-failed` event, no decomposition, no demote, claim released,
reported to `supervise` as the infrastructure-class outcome so it backs off and surfaces the
condition — and for printing the actual Gate B violations instead of discarding them,
**and neglected** retrying the check-in in-session (the common causes are a harness defect or a
concurrent merge, neither of which a retry fixes, and a retry loop on a systematically-invalid
tree spins), preserving the rejected tree for repair (worth doing, but it needs a durable holding
area and a janitor to reap it — a larger design than this defect warrants), and merely guarding
the decompose call while leaving the demote (a demote on a proof that verified is equally
unearned),
**to achieve** an invariant that the swarm never destroys a verified proof or mints permanent
goal files in response to a condition that says nothing about the goal,
**accepting that** the goal stays unproved and must be re-proved from scratch on a later cycle
(the proof is reproducible; the sub-goals would not have been), that a persistent tree-level
defect now presents as repeated infrastructure backoff rather than as forward progress — which
is the intended failure mode, since the alternative is silent permanent damage — and that
`supervise`'s consecutive-infra-failure cap will eventually stop the loop, correctly, until an
operator intervenes.

## Options Considered

### Option 1: Check-in failure is the ADR-016 no-penalty class (Selected)
Distinguish `check_in_proof` failure from `run_proof` failure; release the claim, no event, no
decomposition, no demote; return the infrastructure-class code; print the Gate B violations.
**Pros:** one small change at the seam where the information still exists; reuses an established
principle rather than inventing one; makes the failure diagnosable. **Cons:** the verified proof
is still discarded (re-proved later), and a systematic defect becomes repeated backoff.

### Option 2: Retry the check-in in-session (Rejected)
Re-run `check_in_proof` a bounded number of times. **Rejected:** the observed causes — a harness
defect (#7158) and a stale base — are not fixed by an immediate retry, and a retry loop against a
systematically-invalid tree burns the cycle without changing the outcome. Orthogonal to the
damage this ADR prevents.

### Option 3: Preserve the rejected tree for repair (Deferred)
Park the verified proof somewhere durable and let a janitor re-submit it once the tree-level
problem is fixed. **Deferred, not rejected:** genuinely valuable — a verified proof is expensive
— but it needs a holding area, a reaper, and a rule for staleness against a moving `main`. That
is its own ADR. This one stops the destruction; recovering the artifact can come later.

### Option 4: Guard only the decompose call (Rejected)
Skip `decompose_goal` when the proof verified, but keep the demote. **Rejected:** a demote is
equally unearned — the goal did not resist proof, and ADR-010 affinity is meant to rank goals by
difficulty, not by harness health. Half the fix invites the other half back later.

## Dependencies
| Relationship | ADR ID | Title | Notes |
|--------------|--------|-------|-------|
| Extends | ADR-016 | Infrastructure Failure Is Not Goal Evidence | Applies the same principle to a second condition |
| Constrains | ADR-009 | Goal Decomposition | Narrows decompose-on-failure's trigger: a verified-but-unsubmitted proof is not a failure |
| Constrains | ADR-010 | Affinity-Gap Selection | No demote for a submission-side failure |
| Relates To | ADR-018 | Create-Only Goal Statements | The reason the damage is irreversible and worth an ADR |
| Relates To | ADR-034 | Floored Recompose Demote | Its floor is not reached on this path at all now |
| Relates To | ADR-116 | Suite-Aware Decomposition | Its pilot is what exposed the mechanism (#7151) |

## References
| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Check-in failure guard spec | Specification | specs/SPEC-118-A-Check-In-Failure-Is-Not-Goal-Evidence.md |
| REF-2 | A Gate B rejection destroys the proof and mints permanent goals | Issue | <https://github.com/agenticsnz/unsorry/issues/7159> |
| REF-3 | Spurious decomposition of an already-proved goal (closed unmerged) | PR | <https://github.com/agenticsnz/unsorry/pull/7157> |
| REF-4 | Earlier spurious decomposition; revert closed as invalid under ADR-018 | Issue | <https://github.com/agenticsnz/unsorry/issues/7135> |

## Status History
| Status | Approver | Date |
|--------|----------|------|
| Accepted | unsorry maintainers | 2026-07-29 |
