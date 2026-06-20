# ADR-080: Platform Generalisation and the Self-Verification Gating Invariant

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-080 |
| **Initiative** | unsorry — from a Lean-maths swarm to a general verifiable-problem engine |
| **Proposed By** | unsorry maintainers (prompted by Chris Barlow's alignment request); companion to [ADR-078](ADR-078-Sponsor-Registered-Targets-And-Obligation-Discharge-Credit.md) |
| **Date** | 2026-06-20 |
| **Status** | Draft |

> **DRAFT for ratification** — this touches mission scope, so it is for the
> founders (Chris / Ocean) to ratify, not for me to finalise. Every clause is
> anchored in the founding plan
> ([distributed-research-swarm-plan.md](../proposals/distributed-research-swarm-plan.md))
> so the alignment is provable on the page, not asserted.

## Context

The swarm was built to prove Lean 4 `sorry`s, but two things make "is this still
just a maths project?" a live question: ADR-078 reframes work as discharging
*architected packages* (math or otherwise), and Ocean is bringing a non-maths
target (the Lion verified microkernel proof). The founding plan already anticipated
this **by design** — but it also drew one hard line that generalisation must not
cross.

What the founding plan says, verbatim:
- **The machinery is domain-neutral.** *"The coordination machinery (Components
  §4–§7) is domain-neutral: it would help options 2 and 3 just as much."* AISP
  coordination, claims, gates, the library index, decomposition — none of it is
  maths-specific.
- **Self-verification is the gating criterion.** *"An agent can confirm its own
  output cheaply and deterministically, with no lab and no human. This is the
  gating criterion."* It is *why* it ranked nine candidate domains and chose maths:
  **only a kernel-grade verifier passes it cleanly.** Bio, materials, drug
  discovery, fusion (ranks 4–9) were rejected for lacking an in-software oracle —
  *despite scoring higher on direct benefit.*
- **The soundness guarantee rests entirely on that.** *"The commons cannot be
  poisoned… every contribution is re-checked by the kernel on merge."* Remove the
  kernel-grade verifier and that guarantee is gone.

So generalisation is in the plan's spirit — *for the right domains.* This ADR makes
the boundary explicit so the platform can grow without drifting into a poisonable
commons.

## WH(Y) Decision Statement

**In the context of** a domain-neutral engine now being pointed at non-maths targets
(Lion) under a structural-contribution model (ADR-078),
**facing** the choice between staying Lean-maths-only, opening to *any* problem, or
opening to a *defined class* of problems,
**we decided for** declaring unsorry a **general engine for any domain that carries a
cheap, deterministic, kernel-grade self-verifier** — math, formal software/hardware
verification, and constructions with an exact machine-checkable certificate — under
the non-negotiable **gating invariant** below,
**and neglected** (a) Lean-maths-only (forgoes the planned generality and the
tangible-benefit gain of Lion-class targets the founding doc wanted), and (b)
opening to *any* problem incl. soft-oracle or physically-validated domains (ranks
2–9's weaker oracles) — which would break the gating criterion and make the commons
poisonable, contradicting the founding soundness guarantee,
**to achieve** the founding plan's *Phase 2* ("open lemmas and target theorems by
decomposition") generalised across verifiable domains, moving *up* the
benefit-to-humanity axis the doc admitted was maths's weak spot **without** lowering
the verifier bar,
**accepting that** intake now depends on curated skeleton suppliers (ADR-078), that
each new domain's verifier must be vetted as kernel-grade before it earns the
trustless-commons guarantee, and that mission-scope governance is now an explicit
maintainer responsibility.

## Decision detail

1. **The gating invariant (non-negotiable).** A domain/target is admissible to the
   *trustless commons* **iff** every contribution can be re-checked on merge by a
   **cheap, deterministic, kernel-grade verifier** with no human and no lab in the
   correctness path. This is the founding gating criterion, restated as a hard
   admission rule. It is what keeps "the commons cannot be poisoned" true.

2. **In scope** (carry a kernel-grade verifier):
   - **Formal mathematics** (Lean) — unchanged.
   - **Formal software/hardware verification** — spec + implementation + refinement
     where obligations are proof goals (Lion). *Verified via formal proof, not tests*
     — which is why it passes the gate that test-based software (founding rank #3,
     "tests are a gameable oracle") fails.
   - **Constructions/algorithms with an exact certificate** — where *validity* (not
     optimality) is kernel-checkable (a produced object + a proof it has property P).

3. **Out of scope for the trustless commons** (no kernel-grade oracle): soft-scored
   optimisation, and any physically- or empirically-validated domain (founding ranks
   4–9). They may be explored as *separate, explicitly-weaker* products, but they do
   **not** get the soundness guarantee and must not share the same merge-trust path.
   ADR-052's softer tiers (SCORED/CONSENSUS/APPROVAL) are advisory-only here.

4. **Commons governance.** Curated targets serve the commons: the platform is open
   to **any vetted public-benefit skeleton**, with Lion the first exemplar — not a
   contracting service for whoever arrives first. Target admission and the
   maximum-benefit-to-humanity test are a maintainer/founder decision, recorded
   auditably (natural home: ADR-054 trust tiers + the ADR-078 curated-target layer).

## Consequences

- Makes "are we a general platform now?" an **explicit, aligned decision** instead of
  implicit drift, with the founding criteria as the yardstick.
- The verifier-tier abstraction (ADR-052) becomes the plug-in point for new domains'
  verifiers — but clause 1 means only kernel-grade (VERIFIED-tier) domains join the
  trustless commons.
- Sets up the open question this ADR does **not** answer: *given an admissible
  domain, how is a concrete problem scoped into pipeline-consumable units?* —
  answered by ADR-081 (intake) + SPEC-081-A (`skeleton-validate`).
- **Two-level gate (composition with Leo's ADR-078).** This ADR gates the
  **domain** (does it carry a kernel-grade verifier? — the founding gating
  invariant). Leo's ADR-078 gates the **target within an admitted domain** (is the
  skeleton sponsor-registered, with credited obligations?). Coarse-then-fine: a
  target is only registrable in a domain this ADR has admitted. The two do not
  overlap — domain admissibility vs. per-target credit.

## Open questions
1. Who ratifies a new domain as kernel-grade, and how is it recorded?
2. The commons-vs-contractor governance test for accepting a target.
3. Interaction with ADR-052 tiers: is anything below VERIFIED ever allowed to merge?
