# ADR-081: Problem Admission and the Skeleton Intake Pipeline

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-081 |
| **Initiative** | unsorry — turning an admissible problem into pipeline-consumable work |
| **Proposed By** | unsorry maintainers; operational companion to [ADR-080](ADR-080-Platform-Generalisation-And-Domain-Neutrality.md) and [ADR-078](ADR-078-Sponsor-Registered-Targets-And-Obligation-Discharge-Credit.md) |
| **Date** | 2026-06-20 |
| **Status** | Draft |

> **DRAFT for discussion.** ADR-080 says *which* problems are admissible (policy);
> this says *how* an admissible problem becomes work the swarm can consume
> (mechanism). It is part of a four-ADR set reconciled with Leo's (#3232/#3246):
> **078 (Leo) = how contribution earns credit · 079 (Leo) = deterministic sympy
> solver · 080 = what's admissible (gating invariant) · 081 = how it's consumed
> (this).** `skeleton-validate` (SPEC-081-A) is the registration-time validator
> ADR-078 asks for; the credit function stays ADR-078's.

## Context

The pipeline consumes exactly one kind of thing — an open Lean goal — yet there is
no defined contract for getting a real-world target *into* that form. A
mathematician with a half-formalised theorem, or the Lion team with a kernel proof,
has no checklist for "what must I hand over for the swarm to start discharging my
obligations?" Today that scoping is ad-hoc. This ADR defines the **intake contract**
and the **admissibility validator** so onboarding a target is a repeatable procedure,
not tribal knowledge.

The fixed end of the funnel (what the swarm already eats) is concrete. An open goal is:
- `goals/<id>.aisp` — `⟦Ω:Goal⟧{id; phase≜prove; status≜open; difficulty}`,
  `⟦Γ:Deps⟧{deps≜⟨…⟩}`, `⟦Λ:Artifact⟧{lean≜goals/<id>.lean; sha≜∅; aff}`.
- `goals/<id>.lean` — a Lean statement ending in `sorry` that **type-checks** under
  the pinned context.
- A **pinned verifier context** — `lean-toolchain` + `lake-manifest.json` (mathlib
  rev) — so Gate A re-verifies every contribution from scratch.
- Dependency edges via `decompositions/<parent>.<agent>.aisp` feed ADR-078's credited-obligation accounting.

Everything upstream of that is "scoping." This ADR specifies that upstream.

## WH(Y) Decision Statement

**In the context of** a domain-neutral engine (ADR-080) that consumes only open Lean
goals, with no defined way to turn a real target into them,
**facing** the choice between leaving intake ad-hoc and defining an explicit intake
contract + validator,
**we decided for** a **skeleton intake contract**: a target is admitted as a curated
package only when its supplier provides (1) a type-checking formal **top statement**,
(2) an **architected skeleton** — the decomposition into `sorry` obligations with
dependency edges, (3) the emitted **goal records** for each open obligation, and (4)
a resolvable **pinned verifier context**; validated by a `skeleton-validate` check
before any obligation enters the queue,
**and neglected** ad-hoc intake (unrepeatable, lets ill-formed or unverifiable
targets in, and undermines ADR-078's credit accounting because edges may be unsound),
**to achieve** a repeatable on-ramp a mathematician or the Lion team can follow, that
guarantees every queued obligation is individually checkable and every package is a
real architected tree (so ADR-078's credited-obligation accounting is meaningful and ADR-080's gating
invariant is enforced at intake),
**accepting that** steps 1–2 (formalise + architect) are human/curation work — the
least automatable part — and that the supplier, not the swarm, authors the skeleton.

## Admissibility test (ADR-080, made checkable)

A candidate problem is admissible **iff** all three hold:
1. **Formally statable** with a **kernel-grade verifier** (Lean preferred). The
   verifier *is* the gate (ADR-080 clause 1).
2. **Decomposable** into independent, claimable obligations.
3. Each obligation is **checkable in isolation** (so each merge re-verifies).

Three admissible **shapes**: theorem formalisation · formal software/hardware
verification (spec→impl refinement, e.g. Lion) · construction + exact certificate
(validity, not optimality, is kernel-checkable).

## The intake funnel

```
raw target
 → 1. FORMALISE the top statement   — Lean, type-checks under pinned context   [human]
 → 2. ARCHITECT the skeleton        — decompose into `sorry` obligations +     [supplier]
        dependency edges (the curated tree; NOT swarm-minted)
 → 3. EMIT goal records             — each open `sorry` → goals/<id>.aisp +    [mechanical]
        goals/<id>.lean, deps wired
 → 4. PIN verifier context          — toolchain + library (+ spec/refinement   [mechanical]
        framework for software targets)
 → 5. swarm CONSUMES                — claim → prove → Gate A re-verify → merge; [existing]
        unproved → decompose → re-queue
```
Steps 1–2 are the human front door; 3–5 are existing machinery. **Onboarding a target
= doing 1–2 and producing the artifacts of 3–4.**

## `skeleton-validate` — the intake gate (new)

A submitted package is admitted only if it passes, deterministically:
- **Top statement type-checks** under the declared pinned context (no `sorry` in the
  *statement* itself; the proof obligation is the `sorry`).
- **Every leaf obligation is a well-formed open goal** — `goals/<id>.lean`
  type-checks, ends in `sorry`, and has a matching `goals/<id>.aisp` (`status≜open`).
- **Decomposition edges are sound** — every `sub` resolves to a real goal id; the
  graph is acyclic; `parent` exists; (ADR-078) no degenerate pass-through padding.
- **Verifier context resolves** — toolchain + library pins are valid and Gate A can
  build the package shell.
- **Curated-target provenance present** — the package is attributed to a vetted
  supplier (ADR-080 governance / ADR-054 tiers), not self-minted, so ADR-078's credit accounting
  is farm-proof.

A package failing any check is rejected at intake — never partially queued.

## Consequences
- A repeatable, documented on-ramp (a checklist suppliers follow) replaces tribal
  knowledge; reuses the existing goal/decomposition/Gate-A machinery end-to-end.
- Enforces ADR-080's gating invariant **at the door** (no verifier context / not
  kernel-checkable ⇒ not admitted) and makes ADR-078's credited-obligation accounting trustworthy (edges
  validated, provenance curated).
- Pairs with the **Lion pilot**: Lion is the first package to run through
  `skeleton-validate`, which will surface what the contract is missing for *software*
  targets (the spec/refinement-framework attachment in step 4).

## Open questions
1. Format for the spec + refinement-framework attachment for software targets
   (step 4) — Lion will define this in practice.
2. Should `skeleton-validate` be a Gate (blocking) or an intake tool run by the
   onboarding operator? (Leaning: an intake tool + a CI check on the package PR.)
3. Autoformalisation assistance for step 1 (the founding plan's Phase 0/1 on-ramp)
   vs. requiring suppliers to hand over a type-checking statement.
