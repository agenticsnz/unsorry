# ADR-103: Validator Role — Creditable, Distributed, Reproducible Verification

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-103 |
| **Initiative** | unsorry — decentralised swarm infrastructure (verification as a first-class role) |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-22 |
| **Status** | Proposed |

## Context

unsorry has two operational roles today: **calculators** (provers — `swarm/agent.sh --prove`) that generate candidate proofs, and **dispatchers** (`swarm/run.sh`) that turn locally-verified `queued/prove/*` branches into PRs and meter Gate A load (ADR-058). The expensive, load-bearing *verification* — `lake build UnsorryLibrary --wfail` elaboration, `axiom_audit`, and `leanchecker` kernel replay — runs centrally on paid namespace.so runners. ADR-049 already records the direction to decentralise that heavy verification (a tiered split: the untrusted contributor elaborates; a mandatory cheap **trusted central re-check** stays the sole soundness gate), with the volunteer substrate (ADR-053), verification tiers / auditability (ADR-052), and identity / quotas / reputation (ADR-054) specced around it.

What is *not* yet a first-class concept is **verification as a credited role**. Today a node that only checks proofs earns nothing and is invisible in provenance (`solver≜` / `agent≜` / `provider≜`). Yet — as the operator put it — *without validators, proof calculation does not matter*: a produced proof has no value until something attests it passes the kernel. As verification decentralises (ADR-049), the swarm needs a role that does this checking, is independently auditable, and is rewarded — without that reward becoming a farm for rubber-stamping.

This ADR adds the **validator** role and its credit + anti-foul-play model. It composes ADR-049/052/053/054; it does not relitigate them, and in particular it does **not** weaken ADR-049's invariant that peer attestation is never load-bearing for soundness.

## WH(Y) Decision Statement

**In the context of** unsorry decentralising heavy Gate A verification onto volunteer nodes (ADR-049/053), where checking a candidate proof is a *deterministic, reproducible, binary* kernel result (ADR-002 release pins + ADR-048 byte-identity) — so any node can recompute the same verdict — and where a node that only verifies currently earns no credit and leaves no provenance, even though verification is what gives produced proofs their value,

**facing** (a) the impossibility of *cryptographically* proving that a node ran a deterministic public computation — the verdict is predictable, so a node can sign "valid" with the correct proof-hash, toolchain-hash, and timestamp **without running anything** (proof-of-execution is unattainable for deterministic work); (b) the unsorry-specific hazard that accepted proofs become **imported dependencies** of later proofs (the compounding of ADR-009/010), so a false proof admitted to the protected library cannot be cleanly rolled back — detection after the fact does not undo the cascade; and (c) ADR-049's standing rejection of "redundant N-of-M peer consensus" as a *defeatable vote among non-cryptographic identities* (ADR-007/030: CONSENSUS is reserved for domains with *no* cheap verifier; Lean is VERIFIED),

**we decided for** making **validator** a first-class protocol role — separate from calculator and dispatcher in the protocol, database, rewards, and audit log, though any one node may run several roles in one binary (`unsorry-node --roles calculator,validator`) — whose output is a **signed attestation**: *"registered validator V, on toolchain/mathlib hash T, independently obtained kernel verdict R for proof-hash H, within deadline D."* An attestation is a **claim about execution, never the source of truth**: the Lean kernel remains the sole truth oracle, and the mandatory trusted central re-check (ADR-049) stays the load-bearing gate at the **promotion boundary** into the protected library at **p = 1, unchanged** — peers add a pre-promotion credit / audit / pre-filtering layer, they never substitute for that gate, and any reduction of central re-check below p = 1 is explicitly out of scope here (it would amend ADR-049 and needs its own decision). The guaranteed-honest gate is non-negotiable at the boundary precisely *because* the dependency cascade makes promotion a matter of prevention, not after-the-fact detection. Validators are **credited** for timely correct attestations (and especially for catching invalids) and **penalised** for foul play via reputation loss / slashing, with rubber-stamping made −EV by **honeypots** (known-bad proofs injected at a calibrated rate), **central random re-sampling**, and **peer-vs-central agreement reputation** (ADR-054) — the only available defences, since execution itself cannot be proven,

**and neglected** (a) attestation-as-truth / a pure 2-of-N peer quorum gating promotion with no trusted gate (re-rejecting ADR-049's neglected option — sound only if every accepted proof stays challengeable *and* cleanly reversible, which the dependency cascade defeats); (b) merging dispatcher and validator into one authority (a dispatcher that also validates would become a hidden source of validation truth — its vote must count as exactly one ordinary validator vote, no positional weight); (c) rewarding agreement-with-the-majority (a rubber-stamp incentive — reward correct *participation* and invalid-catching instead); (d) cryptographic proof-of-verification schemes (unattainable for deterministic public computation — a hash of a deterministic output is predictable by anyone holding the answer); and (e) economic slashing as the *primary* soundness guarantee (penalties deter farming and protect *credit integrity*, but correctness rests on the kernel + the trusted gate, never on a penalty being large enough — ADR-049).

## The three roles

| Role | Produces | Trust / incentive |
|---|---|---|
| **Calculator** (today's prover) | candidate proofs — *"I found this proof"* | rewarded for accepted proofs |
| **Dispatcher** (today's `run.sh`) | assignment + queue / ordering metadata | rewarded for reliable coordination / uptime |
| **Validator** (new; decentralised Gate A) | signed reproducible attestations — *"I ran the kernel on hash H and got R"* | rewarded for timely correct attestation; **penalised** for false attestation |

Keep them **separate in protocol / DB / rewards / audit log**; allow one binary to run several (`--roles ...`). A node that validates a proof it also calculated does **not** satisfy the independence requirement for that proof (see promotion rule).

## Attestation, credit, and anti-foul-play

An attestation is **recorded in the audit log** if it is signed by a registered validator (ADR-054 identity), references the exact commit / proof-hash, carries the validator's toolchain / mathlib hash, and arrives within the deadline. It is stored in Git / AISP with a first-class `validator≜` provenance field and surfaced as a validator dimension on the leaderboard.

**Credit** (distinct from calculator credit):
- *base*: a correct attestation on an assigned proof, submitted in time;
- *bonus*: catching an **invalid** proof others missed (high value — the behaviour we most want);
- *never*: credit merely for matching the majority or voting "valid" early.

**Foul play → penalty** (ADR-054 reputation as the substrate):
- a **false attestation** (verdict contradicts the trusted re-check / challenge outcome) → reputation loss / slash;
- tracked signals: `false_attestation_count`, `timeout_count`, `dispute_success_rate`, `validator_reliability_score`.

Because execution cannot be proven, rubber-stamping is deterred *statistically*: **honeypots** (known-bad proofs the validator must reject — attesting one valid is a provable false attestation → penalty), **random central re-sampling**, and the reputation table built from **peer-vs-central agreement**. The honeypot injection rate is a **tunable security parameter**, set so the expected penalty of skipping the work exceeds the reward of a blind "valid" — necessary because, in unsorry, invalid proofs are *rare* (calculators only submit locally-verified proofs), so most validator credit is honest *confirmation*, exactly where rubber-stamping would otherwise pay.

## Promotion rule (phased)

A candidate is **promoted into the protected library** only when a deterministic kernel verdict from a **guaranteed-honest gate** confirms it — peer attestations offload, pre-filter, scale, and earn credit, but do not replace that gate while it exists.

- **Phase 1 — bootstrap.** Calculators produce; ≥3 peer validators attest (≥1 not the calculator); **central CI re-checks 100%**; reputation is built from peer-vs-central agreement; honeypots live. Peer verdicts are *measured*, not yet trusted.
- **Phase 2 — pre-promotion offload (not a promotion gate, never a discard).** A peer quorum (e.g. 2-of-3, ≥1 independent of the calculator, **dispatcher vote unweighted**) **prioritises** candidates and earns credit — it does **not** gate promotion and **never discards** a candidate. The mandatory central re-check stays **p = 1 at the promotion boundary** (ADR-049 / SPEC-049-A unchanged). A peer-**rejected** candidate is not suppressed: it routes to an appeal/sample lane that still reaches the central gate (producer appeal + a sampled fraction + **valid honeypots**), so a false reject is caught and the rejecting validators are penalised exactly like a false accept — closing the proof-suppression hole. Honeypots of **both kinds** (invalid *and* valid) + reputation gate validator standing; an open **challenge window** lets any node overturn a *peer* verdict in **either direction** with a reproducible counter-result (the kernel adjudicates). Reducing central re-check below p = 1 for promotion is **out of scope here** — it would amend ADR-049 and requires its own decision.
- **Phase 3 — cheaper promotion gate (future; would amend ADR-049).** The promotion gate stays guaranteed-honest, deterministic, and **p = 1**, but becomes **cheaper / portable** (e.g. the `lean4export` cross-checker) so its cost falls. Any move to *sample* the promotion gate (central p < 1, leaning on proven peer reputation) is a **separate ADR amending ADR-049's p = 1 invariant**, gated on pilot reputation data — **not decided here**.

## Soundness invariants (restated from ADR-049 for this role)

- The **Lean kernel is the only truth oracle**; an attestation is a claim about execution, never truth.
- Peer quorum is **Byzantine tolerance + credit accounting**, not consensus-as-truth. One honest re-checker plus the kernel overturns any number of false attestations — for **detection**. **Prevention** at the protected boundary is the guaranteed-honest deterministic gate, kept because dependency cascade makes rollback non-clean.
- **Identity is hygiene, never soundness** (ADR-007); reputation / slashing protect credit integrity and deter farming, never correctness.
- Determinism / reproducibility rests on ADR-002 pins + ADR-048 byte-identity; cross-platform reproducibility is hardened by a portable verifier (`lean4export`, ADR-049 roadmap), which also lets a validator check without a full Lean install.

## Relationship to existing ADRs

- **ADR-049** (tiered split + mandatory central re-check) — this ADR adds the *role* and *credit* layer on top and preserves 049's invariant that attestation is never load-bearing.
- **ADR-052** (verification tiers / auditability) — the attestation log is the auditability substrate; validators are the tier operators.
- **ADR-053** (volunteer-scale claim substrate) — validators are volunteers; the substrate carries their assignments + attestations.
- **ADR-054** (identity / quotas / reputation) — supplies validator identity, the reputation table, quotas, and the slashing / penalty mechanism this ADR credits and penalises through.

## Consequences

**Positive.** Verification becomes a credited, auditable, decentralisable role; produced proofs gain explicit, signed **validation provenance** — auditable *pre-finality* evidence (finality itself remains the trusted kernel gate, never a signature); an audited validator reputation table emerges as a by-product; and volunteer validators **scale audit and prioritisation** (fast-tracking likely-good candidates), while a rejected candidate is never discarded — it still reaches the p = 1 gate via appeal/sample, so the system gains audit and ordering without a suppression risk. (Sparing the central gate from doomed candidates is a *future* p < 1 win, not claimed here.)

**Negative / accepted.** Validators need capable machines — the mathlib image is heavy (ADR-049; `lean4export` softens this). N-way peer validation multiplies *total* compute; it is volunteer-borne, so it scales audit/pre-filtering but — on its own — **does not reduce the required central paid compute**: the central re-check stays p = 1 at promotion (ADR-049), so **central cost falls only when the promotion gate itself becomes cheaper or narrower** (e.g. `lean4export`), which is a separate change. Honeypots spend some real verification capacity to police honesty.

**Deferred.** A draft implementation contract — roles wire format, attestation schema, honeypot rate, reputation math, challenge-window mechanics — is in [SPEC-103-A](specs/SPEC-103-A-Validator-Role-And-Attestations.md) (Draft, pre-acceptance); its numeric constants are pilot-calibrated at acceptance, phased like SPEC-049-A.
