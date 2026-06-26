# Study: Peer / Distributed Proof Verification

Status: **Study / exploration** (not a decision). Author: maintainers. Date: 2026-06-18.

Question studied: *can users (peers) validate each other's proofs — a distributed proof-verification system — not just compute proofs centrally?*

This is a study, not an ADR. It maps the design space against what unsorry already
is, surfaces the one hard problem, and recommends a path. It does **not** propose
merging anything yet.

---

## 1. Motivation

Today every proof is verified by one trusted central pipeline (Gate A on
namespace.so runners). This whole week's operational pain — saturation, cancelled
Gate A jobs, the in-flight cap — is **central verifier capacity** being the binding
constraint. "Let peers verify each other's proofs" is, at root, a proposal to
**scale verification past one operator's runners**. The goal is *capacity*.

**Soundness framing (important, and a correction to an earlier draft of this
study).** This proposal spans two regimes that must not be conflated:

- **Advisory peer verification** keeps the current soundness contract *unchanged*:
  the central re-check stays the sole merge-admitting gate (SPEC-049-A §2), peers
  only pre-filter/cache. This is "at least as strong as today."
- **Optimistic acceptance** (admitting a proof on a trusted peer verdict *without*
  central re-check, §7) is **not** a compatible extension — it deliberately
  **supersedes** the current absolute-central-gate policy, trading *absolute*
  soundness for *absolute-by-reproducibility + probabilistic-by-audit*. Adopting it
  requires a future ADR that consciously **supersedes ADR-049 / ADR-052's
  current merge-admission rule**, with the risk explicitly accepted. It is **not**
  "soundness at least as strong as today," and this study should not be read as
  claiming so.

The phased rollout (§10) is built around this split: ship the advisory regime
under today's policy; only enter the optimistic regime behind an explicit
superseding ADR.

## 2. The property everything hinges on: Lean verification is deterministic and reproducible

The trust anchor is the **Lean kernel re-checking proof terms** (`leanchecker`),
plus the axiom audit (whitelist `propext, Classical.choice, Quot.sound`; no
`sorry`/`admit`/`native_decide`) and the ADR-011 statement binding. Given:

- the pinned `lean-toolchain` (e.g. `leanprover/lean4:v4.30.0`),
- the pinned mathlib (`lakefile.toml` rev + committed `lake-manifest.json`, ADR-002),
- the proof source (`library/Unsorry/X.lean`, git-blob identity),
- the **canonical** goal statement (`goals/<id>.lean`, create-only/immutable, ADR-018),

the kernel **ACCEPT/REJECT verdict is deterministic and reproducible on any
machine**. (Olean *bytes* are not reproducible; the *verdict* is — `leanchecker`
re-checks regardless of olean origin.)

**Consequence:** a peer's verdict does not have to be *trusted* — it can be
*re-derived*. Anyone (another peer, the central tier, an auditor) can re-run the
same inputs and must get the same answer. Disagreement is therefore *detectable*.
This is the single most important fact for the design, and it is what makes a
sound distributed scheme possible at all.

## 3. What "peers verify each other" can and cannot mean here

A naive reading is "N users vote; majority wins." For Lean this is **the wrong
model, and the repo already rejected it** (ADR-049, Option 6; ADR-052 tiers):

- Lean is a **VERIFIED** domain — one valid kernel result *is* ground truth. A
  vote among non-cryptographic identities (ADR-007) is a *defeatable poll*, not a
  proof. N-of-M consensus is reserved (ADR-052 CONSENSUS tier) for domains with
  **no cheap deterministic verifier** (e.g. labelling, scoring). Using it for Lean
  adds 200–300% compute and admits *no new signal*.
- Worse, a vote is **Sybil-gameable**: agent IDs are self-asserted (ADR-007), so
  one actor can run M "independent" verifiers and outvote the truth.

So the sound framing is **not** consensus. It is:

> **Reproducible independent re-verification, where a peer's verdict is accepted
> because it is *checkable*, not because the peer is *trusted* — backed by random
> audit and Sybil-resistant reputation so that lying is detectable and irrational.**

This is "optimistic verification" (cf. optimistic rollups, BOINC/SETI redundancy):
trust by default, verify a sample, penalise provable lies.

## 4. The one hard problem

Reproducibility makes lies *detectable after the fact*. But at the moment of
acceptance, the system faces the **"did you actually run the kernel?"** problem:
there is no cheap cryptographic proof that a peer ran `leanchecker` rather than
just signing `accepted=true`. You cannot make producing a verdict expensive-to-fake
the way you can with proof-of-work.

The only sound answers are:

1. **Reproducibility** — any verdict can be re-checked; a lie is caught the moment
   anyone re-runs (and the scheduled full re-replay, ADR-048, guarantees someone
   eventually does).
2. **Random audit** — the trusted tier re-runs a sampled fraction *f* of peer
   verdicts. A peer that lies on fraction *p* of its work is caught with
   probability ~`1-(1-f)^(p·n)` over *n* verdicts → caught fast unless *p* is tiny.
   *Caveat:* random audit is **deterrence**, not a pre-merge bound — a single
   high-value malicious acceptance still survives with probability `1-f` until
   audited. Bounding that risk *before* merge needs the risk-tiered acceptance
   policy in §7.4 (high-impact and trial-tier verdicts get 100% audit), not just a
   uniform sample.
3. **Redundancy with independence** — K independent peers verify the same artifact;
   because the function is deterministic, honest peers *always* agree, so any
   disagreement flags a liar/broken-env. But "independence" must be real (Sybil
   resistance), or K colluding identities just agree on a lie.
4. **Reputation / stake + slashing** — a caught lie slashes the peer's standing
   (loss of accumulated reputation/access), making lying net-negative.

These compose. None alone is sufficient; together they make a peer verdict
*economically and probabilistically* as good as a central one — while *never*
weakening the absolute backstop (the kernel re-check that anyone can perform).

## 5. The invariants a peer verifier MUST honour: soundness *and* host safety

### 5.1 Soundness invariant

From ADR-049 / ADR-011 (the load-bearing rules a distributed verifier cannot relax):

- The verifier MUST re-derive the statement from the **canonical goal source**
  (`goals/<id>.lean`) and bind the proof to it (ADR-011). It must **never** trust a
  contributor-supplied statement or a contributor-supplied `.olean` — both admit
  the *vacuity class* (a real proof of a *weakened/renamed* statement, PR #64) and
  crafted-invalid oleans.
- The verifier MUST run on the **pinned** toolchain + mathlib and record their
  hashes in the verdict — a verdict is only valid under the artifact's pinned
  context.
- The verifier runs the full sound check: build + statement binding + axiom audit +
  `leanchecker`. (This is exactly what Gate A does; a peer is "Gate A on someone
  else's machine".)

### 5.2 Host-safety invariant — the candidate is hostile input

A volunteer runs **untrusted proof/build code on their own machine**, so the work
unit is an attack surface, not just something to check. A malicious candidate can
try to exhaust CPU/RAM/disk, abuse the network, or steal the verifier's signing
credential. The verifier-host contract:

- **Sandboxed build** — run the check in a disposable, network-policied
  container/VM with a clean worktree and hard CPU / memory / disk / wall-clock
  limits. A candidate that exhausts resources or abuses the network is *contained*,
  and the verdict is `error`/`inconclusive`, never a host compromise.
- **No secrets in the sandbox** — the build environment holds **no** signing key,
  token, or credential.
- **Detached signing** — the sandbox emits only a deterministic *result bundle*
  (verdict + context hashes + logs). A **supervisor outside the sandbox** validates
  the bundle's paths/context and signs it. The untrusted job can never sign,
  exfiltrate a key, or forge a verdict (see §9, item 2).
- **Bounded blast radius** — a host compromise must not escalate beyond revoking
  that host's key; it must not implicate the owner's reputation or other hosts.

So a "peer verification" is precisely **ADR-049's decentralised runner, run by a
volunteer, in a sandbox with detached signing, plus an integrity layer (audit +
reputation) that lets its verdict count without being blindly trusted.**

## 6. Design options

| Option | What | Capacity win | Soundness | Verdict |
|---|---|---|---|---|
| **A. Advisory peer pre-check + central gate** | Peers verify to filter/cache; the central kernel still gates every merge | None (central still gates) | Absolute (status quo) | Safe, but doesn't solve the bottleneck |
| **B. Optimistic audited re-verification** | Peers run the full check, sign a verdict; accept on a sufficiently-trusted verdict; central **spot-audits a random sample**; slash provable lies | **High** — most proofs never touch central | Absolute-by-reproducibility + probabilistic-by-audit | **Recommended *future* core — requires a superseding ADR (§1)** |
| **C. K-independent agreement** | K independent peers verify the same artifact; accept on unanimous (deterministic) agreement; any disagreement → escalate to central | Medium (K× cost) | Strong detection, needs real independence | Good complement to B for high-risk items |
| **D. BFT / N-of-M consensus** | Quorum vote decides acceptance | High | **Unsound for Lean** (gameable poll, ADR-049) | Rejected |

## 7. Recommended architecture (synthesis of B + C, on existing primitives)

A layered **"trust-by-reproducibility, capacity-by-audit"** model:

1. **Immutable, content-addressed work unit** (ADR-018/048): goal source + proof
   source + pinned toolchain hash + mathlib manifest hash. This *is* "the exact
   artifact" a verdict refers to.
2. **Peer verifier = decentralised runner** (ADR-049): pulls the work unit, runs
   the full sound check (§5), emits a **signed VerificationEvidence** record
   (ADR-052 schema, *extended* with: verifier identity, verifier public key /
   signature, toolchain+mathlib hashes, artifact hash, verdict, logs link).
3. **Scalable verdict intake** — *not* a central first-push-wins branch. Verdicts
   will be higher-volume than claims, and untrusted peers/forks have no central
   write access, so a single `claims`-style git branch (ADR-004) would reproduce
   exactly the central-contention/scaling failure this study is trying to escape.
   Intake must use an **ADR-053-style pluggable substrate** (sharded refs, an
   append-only log, or an API/queue-backed intake) that accepts verdicts from
   write-less peers and absorbs volume. The AISP record *format* (ADR-003) is
   reusable; the central-branch *transport* is not.
4. **Risk-tiered acceptance + audit policy** (verifier tier × artifact impact).
   Random audit alone is deterrence, not a pre-merge bound — a single high-value
   malicious acceptance survives with probability 1−*f* until audited. So acceptance
   is gated *before* merge by both the verifier's tier and the artifact's impact:
   - **trial-tier verifiers → 100% audited** (every verdict re-checked, or
     corroborated by an independent verdict, before merge).
   - **high-impact artifacts** (library entries many proofs import; toolchain/infra-
     adjacent) → **100% central audit**, regardless of verifier tier.
   - **trusted-tier verdicts on ordinary artifacts** → admit *provisionally* under
     random audit rate *f*, with a defined challenge/audit **SLA** and automatic
     **revert/freeze** if the artifact stays unverified past the SLA or fails audit.
   Tiers are earned from audited-correct *verification* history (item 6), never from
   prover output.
5. **Audit, challenge & rollback operations** (new mechanism): the trusted/central
   tier re-runs the sampled/required fraction; because the check is deterministic an
   honest verdict *always* matches, so any mismatch is a provable lie → slash the
   verifier's verification reputation/tier, **auto-revert/quarantine** the artifact,
   and alert. The audit rate *f*, the per-tier/per-impact audit requirement, and the
   revert SLA together are the soundness/cost dial. A false audit (a verifier's
   broken environment vs. a genuine lie) must be appealable via a reproduction path
   before slashing is final.
6. **Sybil resistance + verifier-specific reputation** (ADR-054, the hard
   prerequisite) — two distinct things an earlier draft wrongly conflated:
   - **Sybil resistance**: identities bound to an accountable owner; only
     *independent owners* count toward corroboration/quorum (one owner = one weight,
     however many agent IDs). Without this, Options B/C collapse.
   - **Verifier reputation must be earned from audited VERIFICATION, not solver
     provenance.** A good *prover* is no evidence of an honest *verifier*. Trust
     comes from the verifier's own audited record — audit-agreement rate,
     false-accept / false-reject history, independence, and revocation events — a
     **separate ledger** from the `⟦Π:Provenance⟧` solver attribution (ADR-023).
     Deriving verifier trust from merged proofs (as an earlier draft did) would let
     a prolific prover become a "trusted verifier" without ever proving it verifies
     honestly.
7. **Backstops (unchanged)**: scheduled full re-replay (ADR-048) and an open
   **challenge** path — anyone may re-run any artifact and publish a counter-verdict;
   a valid challenge forces re-verification and fix-forward. The kernel remains the
   final authority; peers never *lower* the soundness bar, only *share the load*.

The net is: **soundness is still ultimately the kernel** (anyone can re-derive any
verdict; bad merges are detectable and reversible), while **capacity scales with the
number of audited volunteer verifiers** instead of one operator's runner pool.

## 8. Threat model

| Threat | Mitigation |
|---|---|
| **Lazy verifier** signs `accept` without running the kernel | Random audit (deterministic mismatch on a bad accept) + reproducibility + slashing |
| **Lying verifier** accepts an invalid proof | Same; plus corroboration for untrusted tiers |
| **Statement-weakening / vacuity** (real proof of a renamed/weaker goal) | Verifier MUST re-derive statement from canonical source + ADR-011 binding (never trust supplied statement) |
| **Crafted-invalid olean** | Verifier never ingests contributor oleans; rebuilds/`leanchecker` from source on pinned deps |
| **Sybil** (one owner, many "independent" verifiers) | ADR-054 owner binding + reputation + independence accounting; only independent identities corroborate |
| **Collusion** (K colluding verifiers agree on a lie) | Random central audit is owner-independent and unbeatable by collusion; audit rate sets the bound |
| **Reputation farming** (self-verify own proofs to climb tiers) | Verifier ≠ prover separation for reputation credit; audit; cross-owner corroboration |
| **Toolchain mismatch** (verdict under a different toolchain) | Pinned context hashes in the verdict; verdict invalid if context hash ≠ artifact's |
| **Grinding** (retry until a lie slips audit) | Slashing on first catch makes expected value negative; low audit-survival probability over many attempts |
| **Hostile candidate → resource exhaustion** (CPU/RAM/disk/wall bomb on the verifier host) | §5.2 sandbox with hard resource + wall-clock limits; over-limit ⇒ verdict `error`, host unharmed |
| **Hostile candidate → network abuse** (build phones home / attacks third parties) | §5.2 network-policied sandbox (egress denied/allowlisted) |
| **Signing-credential theft** (malicious build reads the key and forges verdicts) | §5.2 detached signing — no key in the sandbox; supervisor signs the validated result bundle outside the untrusted job |
| **Host compromise escalation** (one bad host → owner reputation / other hosts) | Per-host key; bounded blast radius (revoke that host's key only) |

## 9. What already exists vs. what must be built

**Reusable today:** kernel determinism + `leanchecker` (the anchor); ADR-048
immutable-artifact/provenance + verify-once; ADR-002 pinning; ADR-018
content-addressing; the ADR-003 AISP record *format* (for the verdict record);
ADR-052 evidence schema (centralised form); ADR-049 decentralised-runner soundness
rules. (ADR-004's *central first-push-wins branch transport* is **not** reusable for
verdict intake — see §7.3.)

**Must be built (mapped to ADRs):**
1. **Sybil-resistant identity + verifier-specific reputation** — ADR-054 (Proposed,
   unbuilt), extended with a **verifier ledger** (audit-agreement, false-accept,
   false-reject, independence, revocation — §7.6) kept *separate* from solver
   provenance. *Hard prerequisite.* Without it, nothing here is safe.
2. **Signed verdicts + detached signing** (§5.2) — extend ADR-052 evidence with
   verifier identity, context hashes, and a signature. **Detached signing is
   mandatory:** the untrusted build sandbox emits a deterministic *result bundle*
   only; a supervisor *outside* the sandbox validates the bundle's paths/context and
   signs it, so the signing key is never reachable by candidate code. A PAT is **not**
   a signing primitive (it is a coarse bearer credential and must never sit inside a
   build job) — use a dedicated per-host signing key (or a minimal verifier PKI / a
   GitHub App attestation), held only by the supervisor and per-host revocable.
3. **Sandboxed decentralised verifier worker** — ADR-049 (Accepted, Phase 1 not
   pursued): the volunteer "Gate A on your machine" honouring **both** §5.1
   (soundness) and §5.2 (host isolation: disposable sandbox, resource + network
   limits, no secrets inside).
4. **Risk-tiered audit + challenge + rollback** — *new*: per-tier/per-impact audit
   policy, random sampler, counter-verdict/challenge handling, auto-revert/freeze,
   slashing with an appeal/repro path. This is the integrity core and the main novel
   work.
5. **Scalable verdict intake** — an ADR-053-style pluggable substrate or API/queue
   intake (§7.3), *not* a central first-push-wins branch (which would re-create the
   contention this study is trying to escape, and excludes write-less peers/forks).

## 10. Phased rollout

1. **Phase 0 — Advisory (Option A), under today's policy.** Peers run the full check
   and publish *signed verdicts* into the verdict substrate (§7.3), but the central
   kernel still gates every merge. **Soundness unchanged** (current ADR-049 rule
   holds). Builds the verdict schema, signing, the verifier ledger, and a corpus of
   peer-vs-central agreement data to *measure* honesty before trusting it. **No
   *superseding soundness* ADR needed** — but this is not zero-ADR: signed verdicts,
   the verdict substrate, key/sandbox handling, and verifier-ledger semantics are
   new identity/evidence/control-plane surfaces that still need **ADR-052 / ADR-053 /
   ADR-054 updates or specs** before build.
2. **Phase 1 — Audited trusted-tier (REQUIRES A SUPERSEDING ADR).** This is the
   regime that *changes* the soundness policy (§1): a `trusted` verdict admits a
   proof *without* central re-check, under the §7.4 risk-tiered audit (trial = 100%
   audit; high-impact = 100% central; trusted/ordinary = provisional at rate *f*
   with a revert SLA). Must be gated behind an explicit ADR that supersedes
   ADR-049/052's merge-admission rule and accepts the absolute→probabilistic trade.
   Requires ADR-054 (incl. the verifier ledger) + the audit/rollback core.
3. **Phase 2 — Corroboration for trial tier (Option C).** New/low-rep verifiers'
   verdicts admit only with an independent *(distinct-owner)* second verdict; widens
   the verifier pool safely.
4. **Phase 3 — Tune.** Lower *f*, raise tiers, as measured honesty justifies; keep
   the scheduled full re-replay and challenge path as permanent backstops.

## 11. Honest assessment / recommendation

- **For soundness, peer *consensus* is unnecessary and was correctly rejected.** The
  kernel is ground truth; a vote can only weaken it. Do not build Option D.
- **For capacity (the actual problem), peer verification is viable** — but *only* as
  Option B/C: reproducible re-verification, audited, Sybil-gated. It is essentially
  **ADR-049 (decentralised runner) + ADR-054 (Sybil-resistant identity + verifier
  ledger) + a new risk-tiered audit/rollback layer + signed ADR-052 evidence.** That
  is a substantial, multi-ADR build, and it trades *absolute* soundness for
  *absolute-by-reproducibility + probabilistic-by-audit* — a **conscious
  supersession** of ADR-049/052's current merge-admission rule (§1), to be made in an
  explicit ADR, not a silent extension. The trade is defensible (the kernel backstop
  and challenge path keep any error detectable and reversible), but it *is* a change
  to the soundness policy.
- **Cheaper near-term alternative worth weighing first:** the central verifier's
  kernel replay is sharded and embarrassingly parallel *by design* (ADR-063 — the
  tooling has landed but it is still **Proposed/pilot**: behind the non-required
  `gate-a-shard-pilot` workflow, not yet promoted into the required gate). Once
  promoted, much of the desired capacity win is obtainable by running *that* across
  more (even volunteer) machines with **spot-audit** — i.e. Option A→B *without*
  full peer autonomy. If the goal is purely throughput, "audited decentralised
  runners" may deliver most of the benefit at a fraction of the trust-machinery
  cost.
- **Prerequisite gate:** none of B/C is safe until **ADR-054 (identity / Sybil /
  reputation)** is built. That should be the first concrete step regardless of how
  far toward peer verification we go.

## 12. Open questions

- Signing/key management: GitHub-account attestation vs. a minimal verifier PKI?
- How is verifier *independence* actually established (owner binding is necessary;
  is it sufficient)?
- Audit rate *f*: what soundness target, and who pays for the audit compute?
- Governance of slashing (false-positive audits from a verifier's broken env vs.
  genuine lies — needs an appeal/repro path).
- Reproducibility edge cases (toolchain bugs, platform-specific kernel behaviour)
  that could make an honest verdict differ — how rare, how detected.
