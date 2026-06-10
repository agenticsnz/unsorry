# Contributor-Readiness Checklist Evidence (v1.0.0)

This document is the contributor-readiness evidence record for `agenticsnz/unsorry`
and forms the body of the **v1.0.0** release. Each of the six readiness items (a)–(f)
was assessed by an independent **adversarial verifier** that cloned the repo fresh,
re-ran the load-bearing checks rather than trusting the metrics prose, pulled live CI
logs, and probed for evasion paths. A separate runner executed the README quickstart
end-to-end from a clean clone.

**Result: all six items are `sufficient` (high confidence).** No verifier returned
`insufficient`. The caveats each verifier raised are reproduced honestly below —
especially the (b) shared-GitHub-account authorship caveat and the (a)
statement-vs-canonical-binding gap deferred to Phase 1. Honesty is the product:
nothing here is papered over to reach v1.0.0.

Verification environment: repo cloned at `main` HEAD `1771cd8`. Date of assessment:
2026-06-10.

---

## (a) Gate A has rejected real bad input on real PRs

**Claim.** Gate A (the soundness gate) has rejected real bad input on real PRs — not
just in theory.

**Verdict: `sufficient` · confidence: high.**

**Evidence.**

- All 9 red-team bypass PRs were verified independently via
  `gh pr view --json statusCheckRollup`: each is **CLOSED**, `mergedAt=null`, and
  reports `gate-a` conclusion **FAILURE**. The fix PR
  [#65](https://github.com/agenticsnz/unsorry/pull/65) is **MERGED** at
  `2026-06-10T04:34:37Z`.
- The metrics file was **not** trusted. The verifier pulled the actual failed CI logs
  (`gh run view --log-failed`) and matched the failing **step** to each claimed vector:
  - [#56](https://github.com/agenticsnz/unsorry/pull/56) bare `sorry` → fails at
    `lake build --wfail` with `declaration uses sorry`.
  - [#61](https://github.com/agenticsnz/unsorry/pull/61) `native_decide` → fails at the
    **Axiom audit (authoritative)** step with
    `VIOLATION big_pow_mod_zero: depends on axiom ...native_decide.ax_1_1`, confirming
    the audit is genuinely load-bearing (the build is blind to `native_decide`).
  - [#62](https://github.com/agenticsnz/unsorry/pull/62) new-axiom → fails at the
    `axiom_audit` step.
  - [#64](https://github.com/agenticsnz/unsorry/pull/64) `autoImplicit` → fails at the
    **Forbidden elaboration options in library** step with
    `FORBIDDEN library/Unsorry/Attack6.lean: re-enables set_option autoImplicit true`.
- The #64 re-run is confirmed **post-fix**: its gate-a run started
  `2026-06-10T04:35:21Z`, after #65 merged at `04:34:37Z` — so the autoImplicit
  survivor genuinely now fails.
- All claimed Gate A layers were confirmed present in
  [`.github/workflows/gate-a.yml`](https://github.com/agenticsnz/unsorry/blob/main/.github/workflows/gate-a.yml):
  lean-action build, `--wfail` zero-warning build, authoritative
  `axiom_audit`/`collectAxioms`, leanchecker kernel replay, audit self-test,
  `check_library_options`, textual-lint belt.
- The check was **re-run independently**: the real `Attack6.lean` payload from
  `origin/redteam/autoimplicit` was run through
  [`tools/gate_a/check_library_options.py`](https://github.com/agenticsnz/unsorry/blob/main/tools/gate_a/check_library_options.py)
  → exit 1, catching the split-line `set_option` (whole-file, NFC-normalized,
  whitespace-collapsed regex — line-splitting and unicode tricks cannot evade it). The
  tool's own suite: 12/12 pass.
- [`docs/metrics/gate-a-redteam-001.md`](https://github.com/agenticsnz/unsorry/blob/main/docs/metrics/gate-a-redteam-001.md)
  is on `main` (merged via #66, tagged `v0.5.0`); 10 red-team branches are retained on
  `origin` for audit.

Representative CI evidence:
[Actions run 27253447146 / job 80482647068](https://github.com/agenticsnz/unsorry/actions/runs/27253447146/job/80482647068).

**Caveat (honest, disclosed by the project, does not undermine this item).**
Gate A has **no statement-fidelity layer**: no check binds a merged library theorem's
actual statement to its claimed canonical goal/sha. A vacuously-true or mis-stated
theorem under a plausible name is sound but meaningless and would pass
build + audit + leanchecker. #65 closed only the **specific** autoImplicit instance;
the general class (statement-vs-canonical binding) remains open and is documented
verbatim in the metrics doc, which defers the proper fix (statement-vs-canonical-sha
binding / autoformalisation) to **Phase 1**. Because the disclosure is honest and this
item is narrowly "rejected real bad input on real PRs" — soundness-breaking input,
which it provably does on real closed PRs with red CI — the verdict is `sufficient`.
Minor: the attack fixtures (`Attack0-6.lean`) live on the closed branches and were not
merged to `main` (correct), so the durable evidence is the closed-PR CI history + the
metrics doc, both verified live. The verifier pulled per-step failing logs for 4 of 9
vectors (#56/#61/#62/#64) in full detail and confirmed `gate-a=FAILURE` for the other
five.

---

## (b) A non-author agent has merged a proof end-to-end

**Claim.** A non-author (swarm) agent has merged a proof end-to-end.

**Verdict: `sufficient` · confidence: high.**

**Evidence.**

- The three merged library modules exist on `main` and are sorry/axiom-free:
  `library/Unsorry/IntAddNeg.lean`, `IntNegNeg.lean`, `AndCommImp.lean`. A grep for
  `sorry|admit|native_decide|axiom|implemented_by|sorryAx` returns nothing; the
  lakefile has `autoImplicit=false`.
- The soundness check was re-run at the source of truth: the verifier pulled the actual
  gate-a CI job log for the #74 merge run
  ([job 80498487334](https://github.com/agenticsnz/unsorry/actions/runs/27258548944/job/80498487334))
  — the real audit ran (`lake build UnsorryLibrary --wfail`; `axiom_audit` emitting
  footprint `int_neg_neg_thm:[]`, `and_comm_imp_thm:[]`, `int_add_neg_thm:[propext]`;
  leanchecker kernel replay; `test_audit.sh` self-test passing 16/16 with bare-sorry,
  term-sorryAx, new-axiom, and native_decide all correctly rejected). Not a vacuous
  short-circuit.
- `gate-a` / `detect` / `gate-b` / `aisp-advisory` = success on all three merge commits
  (`1aadb16`/#70, `c2d4bda`/#72, `6eb9248`/#74), confirmed via `gh api`.
- [#70](https://github.com/agenticsnz/unsorry/pull/70),
  [#72](https://github.com/agenticsnz/unsorry/pull/72),
  [#74](https://github.com/agenticsnz/unsorry/pull/74) are state **MERGED**.
- Agent identity (`prover-alpha`) appears in commit subjects
  (`claim:`/`prove()`/`release:` ... `prover-alpha`) and PR titles;
  `git log --all` shows **no** `prover-*` id is ever a git author or committer (only
  Chris Barlow, Claude Fable 5, `unsorry-reaper[bot]`).
- Novelty confirmed: seed `goals/int-neg-neg.lean` is only `by sorry`; the proof term
  `:= Int.neg_neg n` appears only in commit `ae8cf63` + its merge.
- Main HEAD merge commit: `6eb92482ae507898f26349b44f11a49d885d24d2`.

**Caveat — the GitHub-author caveat (disclosed, prominent, matches reality).**
"Non-author agent" holds in the **swarm `AGENT_ID` sense**, not cryptographically. By
**ADR-007** design the agent runs under the maintainer's shared GitHub account and
git-author identity: `gh pr view #74` shows author `cgbarlow`, `is_bot:false`, and git
author `Chris Barlow`. The merged proofs are trivial one-liners
(`Int.neg_neg n`, `Int.add_right_neg n`, `⟨h.2, h.1⟩`), so the artifacts alone cannot
distinguish "autonomous agent wrote it" from "maintainer hand-wrote it under an agent
label." The claim of non-human authorship rests on **trusting the orchestration trail**
(claim/release commit markers + PR workflow), not on cryptographic proof. This is
exactly the limitation the §HONEST CAVEAT (ADR-007) section of `phase1-run-001.md`
discloses, in a prominently labeled section that matches reality. Second disclosed gap:
the `metrics.jsonl` event stream is **not** committed to the repo (lives uncommitted on
the workspace; bravo's jsonl was unreadable due to ENOSPC), so the
"jsonl events carry `agent:prover-alpha`" leg cannot be reproduced from a clone — only
the commit-subject and PR-title legs are independently verifiable (and they suffice).
Verdict `sufficient` because the claim is scoped to "a distinctly-identified swarm agent
produced a novel proof that passed the real soundness gate and merged to `main`, with
the shared-account caveat disclosed" — every part independently confirmed.

---

## (c) Claim-collision handling works under concurrency (first-push-wins + TTL reaping)

**Claim.** Claim collisions and TTL reaping were observed under concurrency
(first-push-wins arbitration + TTL reaping of dead claims).

**Verdict: `sufficient` · confidence: high.**

**Evidence.**

- The reap commit `09ba7efe` on the `claims` branch is authored by
  `unsorry-reaper[bot]` and deletes **only**
  `claims/nat-le-trans.trial-dead.aisp` (1 file, 7 deletions). It is the **sole**
  `reap:` commit in the branch history (every other removal is a `release:` by the
  owning agent).
- The planted dead claim: `ts=2026-06-10T00:03:30Z`, `ttl=7200` → expiry `02:03:30Z`;
  arithmetic to the `03:18:32Z` reap = **4502s**, matching the metrics exactly.
- The reaper was **re-run independently**: the pre-reap tree was reconstructed via
  `git archive 09ba7efe~1`, then `python3 -m tools.gate_b.reaper` was run with `--at`
  injection — **before** expiry (`01:00Z`) it kept the claim (`kept:1, reaped:[]`);
  **after** expiry (`03:18:32Z`) it reaped exactly 1 with
  `expired_for_seconds:4502`. The reaper unit suite: 10/10 pass.
- Live CI: [run 27250773072](https://github.com/agenticsnz/unsorry/actions/runs/27250773072)
  (workflow_dispatch, success, 7s) emitted the exact reaped JSON with the dead claim;
  the pre-expiry dispatch run `27245383354` reaped nothing; the cron-`schedule` run
  `27254569302` succeeded and ran the reaper correctly.
- Collision timeline reconstructed from claim-file timestamps on the `claims` branch:
  `charlie` claimed `nat-le-trans` at `03:07:27` and `alpha` at `03:07:33` (cap of 2
  full), then `bravo` claimed a **different** goal `nat-leq-self` at exactly `03:07:35`
  (the metrics' stated collision time) and only got `nat-le-trans` at `03:08:01` after
  the cap freed — corroborating collision → next-goal recovery.
- First-push-wins is implemented (`swarm/agent.sh` `claim_goal`, lines 660–692) and
  **demonstrated** by running `bash swarm/agent.sh --self-test`: **19/19 pass**,
  including `test_claim_push_reentrancy`, whose log shows a genuine non-fast-forward
  rejection → rebase-from-scratch → retry success, plus a real cap-full collision
  withdrawal. Design intent: ADR-004 + SPEC-004-A.

**Caveats (three findings, none fatal).**

1. **Metrics prose inaccuracy.** The file claims the `00:44:22Z` dispatch run
   "correctly kept the claim," implying deliberate live-claim sparing — but the dead
   claim file was not committed until `03:03:30Z` (commit `a5dd46b`, ~2h19m later). At
   `00:44` the reaper saw an empty claims dir (`kept:0, reaped:[]`); it kept nothing
   because there was nothing there. The narrative **overstates** this specific run.
   Live-claim safety is still genuinely shown structurally (only `reap:` commit; all
   else `release:`) and by the before-expiry re-run.
2. **Live-trial first-push-wins is asserted, not artifact-reproducible.** Rejected
   pushes leave no commit, and the metrics honestly states the rebase-retry race counts
   (alpha 2, bravo 4, etc.) are "visible only in supervisor stderr," which is not in the
   repo. The **mechanism** is reproducible via `--self-test`; the live-trial
   arbitration tallies cannot be independently verified from committed artifacts.
3. The metrics' own open caveat ("observing a cron-triggered reap remains open") is now
   actually **closed** by the real `event:schedule` run `27254569302` — evidence is
   **stronger** than the file claims.

Net: the claim survives. Tightening to consider for the public invitation: correct the
misleading `00:44`-run gloss and add an on-repo collision-event log so live
first-push-wins is not stderr-only.

---

## (d) Statement-diff false-positive rate < 20%

**Claim.** The statement-diff (fidelity) false-positive rate is < 20%.

**Verdict: `sufficient` · confidence: high — but rescued at the boundary; read the caveat.**

**Evidence.**

- The fidelity normalizer (`tools/fidelity/normalize.py`, on `main`) was **re-run
  independently** on the two exact flagged pairs:
  - `nat-le-refl`: `∀x∈ℕ:x≤x` vs `∀n∈ℕ:(n≤n)` both normalize to `∀x₁∈ℕ:x₁≤x₁`
    → sha `bdfe3dd8...` (matches the documented `bdfe3dd8…`).
  - `nat-zero-identity-add`: `∀n∈ℕ:n+0≡n` vs `∀n∈ℕ:(n+0≡n)` both → sha `84f38b99...`
    (matches the documented `84f38b99…`).
- Application parens `P(x)` stay **distinct** from `Px` (sha `9b33b3c` vs `2be2750`),
  so the fix is **not** an over-broad paren strip.
- Full fidelity suite: **151 passed** (incl. 17 paren tests with explicit
  meaning-bearing-paren guards: `(n≤n)∧⊤` != `n≤n∧⊤`). Adversarial regression sweep:
  0 of 8 "distinct" pairs wrongly collapsed to MATCH; 0 of 11 "equivalent" pairs failed.
- `fp_rate` arithmetic checked by hand: `1/8=0.125`; `2/10=0.20`; `0/10=0`.
- [PR #50](https://github.com/agenticsnz/unsorry/pull/50) is **MERGED** on `main`
  (commit `b26d066`, `normalize.py` step 5 present on `main`);
  [#48](https://github.com/agenticsnz/unsorry/pull/48) and
  [#49](https://github.com/agenticsnz/unsorry/pull/49) MERGED — all 10 goals decided
  (`goals_translated:10`, `goals_flagged:0`).
- Kill-criterion definition confirmed: `fp_rate >= 0.20` (METRICS.md:53,
  SPEC-003-D:36). Planted pairs confirmed (via `backlog/*.md`) to be genuine
  independently-worded semantic duplicates.

**Caveat — the headline "< 20%" is genuinely fragile; a skeptic should note it crossed
the line.** The frozen at-observation rate of `0.125` is below threshold **only**
because 2 of 10 goals were still undecided (1 flag / 8 decided). Once all 10 goals were
decided **pre-fix**, the strict rate was exactly **`0.20 = 2/10`**, which by the repo's
own documented kill criterion (`fp_rate >= 0.20`) **trips** the criterion — the doc
admits this verbatim ("0.20, exactly at the kill-criterion boundary"). So "< 20%" does
not hold as-originally-measured; it survives **only** because same-day PR #50's
normalizer fix re-diffs both flags to MATCH for a true `0/10`. That fix was verified
legitimate (re-run; shas match; no over-stripping regressions; meaning-preserving
guards present), so the final `0/10` is honest and the claim is ultimately sufficient —
but it is a "rescued at the boundary by a post-hoc fix" result, not a
comfortably-margined measurement. Two narrower caveats: (a) both flags shared a single
mechanical root cause (binder-body paren wrap), so `0/10` reflects **one fix class**,
not breadth across diverse divergence types; (b) the trial is on a 10-goal known-true
elementary backlog where every flag is an FP by construction — the metric says nothing
about the **false-negative** rate (truly-divergent translations wrongly matched), which
is the more dangerous failure mode and is untested here.

---

## (e) `swarm/protocol.aisp` exists and validates

**Claim.** `swarm/protocol.aisp` exists and validates.

**Verdict: `sufficient` · confidence: high.**

**Evidence.**

- `swarm/protocol.aisp` exists (3737 bytes), read in full: 8 AISP blocks (Ω Foundation,
  Σ Records, Γ Claims/Fidelity/Affinity, Λ Loop, Χ Errors, Ε evidence).
- The validator was **re-run independently**:
  `npx --yes aisp-validator@0.3.0 validate swarm/protocol.aisp` → **exit 0, ✓ VALID,
  Tier ◊⁺⁺ Platinum, δ=1.000, ρ=1.814, ambiguity 0.010, mode js**. Re-run twice —
  byte-identical (deterministic). Package is real and pinnable
  (`npm view aisp-validator@0.3.0 version` → `0.3.0`).
- SPEC-003-D §22 requires **≥ Gold (◊⁺)**; §23 records authoring-time **◊⁺⁺ Platinum
  δ=1.000 ambiguity 0.010** — exactly reproduced. Acceptance criterion 1 (exit 0 at tier
  ≥ ◊⁺) is met.
- The advisory CI job `aisp-advisory` in `.github/workflows/gate-b.yml` has
  `continue-on-error:true`; gate-b run
  [27264333534](https://github.com/agenticsnz/unsorry/actions/runs/27264333534) on the
  latest `main` push succeeded, the `aisp-advisory` job conclusion is **success**, and
  its log shows the identical ✓ VALID / Platinum / δ=1.000 / ρ=1.814 output.
- The load-bearing in-repo validator `python3 -m tools.gate_b validate .` → exit 0.

**Caveats (bound the strength of "validates"; do not change the verdict).**

1. **The upstream `aisp-validator@0.3.0` is lenient.** A negative control showed a
   corrupted file (appended garbage with an unbalanced `⟦` bracket) still passes at
   Platinum with exit 0 (ρ dipped to 1.711); only an **empty** file is rejected
   (✗ INVALID, ⊘ Reject, exit 1). So "validates at Platinum" certifies generic AISP
   syntax/density/tier, **not** strict structural correctness or any `unsorry` domain
   schema. ADR-003 explicitly characterizes the package this way and deliberately makes
   it advisory-only, with the load-bearing checks in `tools/gate_b` (which also passes).
2. **Minor doc inconsistency.** SPEC-003-D §22 states the bar as "Gold (◊⁺) or better"
   while `swarm/README.md` and `CHANGELOG.md` headline "◊⁺⁺ Platinum." Not contradictory
   (Platinum exceeds Gold) and §23 reconciles them, but the advertised tier differs
   across docs.

The file exists, parses, exits 0, and clears the required ≥◊⁺ bar with margin — verified
by independent re-run and by the green CI job.

---

## (f) The README quickstart actually runs

**Claim.** The README "Running an agent" quickstart actually runs from a fresh clone.

**Verdict: `sufficient` · confidence: high. Clean-clone runner: `ran_clean: true`.**

**Static verification.** Every command in README L60–76 was checked against the real
repo: clone + `cd unsorry` (dir name matches); `lake exe cache get` (canonical mathlib
incantation, mathlib4 present in `lake-manifest.json`); `lake build` (lakefile.toml
`defaultTargets=[UnsorryLibrary, UnsorryGoals]`); `python3 -m tools.gate_b validate .`
(actually run from a clean clone → exit 0, 30 records, `ok:true`; negative control on a
corrupted tree → `ok:false count:9`, proving the pass is real);
`./swarm/agent.sh --prove --once` (executable; flags parsed at lines 1623–1632;
`bash -n` passes; `--self-test` run → **19/19 PASS**, exit 0).

**Clean-clone runner — step table.** The dedicated runner cloned fresh and executed the
quickstart end-to-end:

| # | Command | Exit | Note |
|---|---|---|---|
| 1 | `git clone https://github.com/agenticsnz/unsorry && cd unsorry` | 0 | Clean clone. Path adjusted to `/workspaces` because `/tmp` had only ~20M free (environmental, not a README defect); command otherwise verbatim. |
| 2 | `export PATH="$HOME/.elan/bin:$PATH"` (env setup) | 0 | lake/lean not on PATH in a bare shell; elan toolchain present. README prerequisites cover the Lean toolchain via elan, so expected env setup. `lake --version` → Lake 5.0.0 / Lean 4.30.0, matching `lean-toolchain` pin `leanprover/lean4:v4.30.0`. |
| 3 | `lake exe cache get` | 0 | Fetched/decompressed prebuilt mathlib (8283 cached files, "Completed successfully in 14435 ms"). Did exactly what README claims — fetch prebuilt mathlib, never builds from source. Warm cache here; README warns it can take minutes cold. |
| 4 | `lake build` | 0 | "Build completed successfully (586 jobs)." Ends clean as README claims. The `declaration uses sorry` warnings are on `goals/*.lean` placeholder theorems (the open backlog the swarm is meant to prove) — expected, not errors; the `Unsorry.*` library builds warning-free. |
| 5 | `python3 -m tools.gate_b validate .` | 0 | Pass (validator silent on success). Ran under Python 3.11.2; README prereqs name 3.12, but gate_b ran fine on 3.11 (environmental, no defect). |
| 6 | `./swarm/agent.sh --self-test` | 0 | "self-test: all 19 tests passed." README L74 says "Run `./swarm/agent.sh --self-test` to check your setup" — does exactly that. |
| 7 | `./swarm/agent.sh --prove --dry-run` | 0 | "dry-run: would claim goal int-sub-eq-add-neg," 17 candidates listed, claimed nothing — exactly as README describes for `--dry-run`. Substituted for the literal `--prove --once` per task instruction to avoid opening a real PR / a long mathlib build; the full prove cycle is exercised by Phase-1 metrics. |

**Deviations (no undocumented fixes needed).** Every documented command ran with exit 0
and did what the README claims. The three adjustments (clone path to `/workspaces` for
disk space; `export PATH` for the elan toolchain covered by README prereqs; substituting
`--prove --dry-run` for `--prove --once` per explicit task instruction) are all
environmental or task-sanctioned, none are README defects.

**Caveats.** Two Lean-dependent commands (`lake exe cache get`, `lake build`) could not
be executed in the static-verifier env (no Lean toolchain) — but the dedicated runner
executed both with exit 0. Residual unfalsifiable-here points: (a) `lake exe cache get`
depends on the upstream mathlib cache being published for the pinned `v4.30.0` rev
(`c5ea0035`) — ADR-002 says release-tag caches are guaranteed, and the runner's warm
fetch confirms it on at least one host; (b) the full `--prove --once` path additionally
needs authenticated `claude` + `gh` and a claimable goal, exercised by Phase-1 metrics
rather than in the quickstart run. Minor non-blocking nit: README prereqs say
Python 3.12 but `gate_b` runs cleanly on 3.11 — the stated prereq is stricter than
reality, not a failure.

---

## Overall readiness statement

`agenticsnz/unsorry` is **ready for public contributor invitation at v1.0.0.** All six
contributor-readiness items (a)–(f) were independently verified `sufficient` at high
confidence by adversarial verifiers who cloned the repo fresh, re-ran the load-bearing
checks, pulled live CI logs, and probed for evasion paths; the README quickstart runs
clean from a fresh clone. The soundness gate (Gate A) has demonstrably rejected real
soundness-breaking input on real, now-closed PRs with red CI; a distinctly-identified
swarm agent has merged a novel, sorry/axiom-free proof end-to-end through that gate;
claim-collision arbitration and TTL reaping are observed and reproducible; the
statement-diff false-positive rate finished at `0/10` after a verified normalizer fix;
the coordination protocol validates at the required tier; and a newcomer following the
README can build the library and run the agent.

This readiness is asserted **with its limitations stated, not hidden** — the caveats
below are carried forward into the public invitation. Honesty is the product.

## Known limitations carried into the public invitation

- **Statement-binding gap (Gate A, item (a)).** Gate A has no statement-fidelity layer:
  nothing binds a merged library theorem's actual statement to its claimed canonical
  goal/sha. A vacuously-true or mis-stated theorem under a plausible name is sound but
  meaningless and would pass build + audit + leanchecker. PR #65 closed only the
  specific autoImplicit instance; the general class remains open and is **deferred to
  Phase 1** (statement-vs-canonical-sha binding / autoformalisation).

- **Shared-account / non-cryptographic authorship (item (b)).** Swarm agents run under
  the maintainer's shared GitHub account and git-author identity (ADR-007), so
  "non-author agent" holds in the swarm `AGENT_ID` sense, not cryptographically. The
  merged proofs are trivial one-liners; non-human authorship rests on trusting the
  orchestration trail (claim/release commit markers + PR workflow), not on cryptographic
  proof. The `metrics.jsonl` telemetry is not committed to the repo, so the jsonl leg of
  agent identity cannot be reproduced from a clone.

- **Prove merge-rate and build friction (Phase-1).** The Phase-1 prove cycle ran 3
  prover agents on sonnet with `merge_rate 0.6` (3 of 5 attempts merged) on an
  elementary backlog. The prove path requires a (sometimes cold, minutes-long) mathlib
  cache fetch and authenticated `claude` + `gh`; the full `--prove --once` cycle is not
  exercised by the README quickstart and is a real friction point for new contributors.

- **Fidelity metric is boundary-rescued and narrow (item (d)).** The `< 20%` FP rate
  held only after a same-day normalizer fix; the pre-fix all-decided rate was exactly
  `0.20`, on the kill-criterion boundary. The `0/10` reflects a single fix class
  (binder-body paren wrap) on a 10-goal known-true backlog, and says nothing about the
  more dangerous **false-negative** rate (truly-divergent translations wrongly matched),
  which is untested.

- **Lenient AISP validator (item (e)).** The upstream `aisp-validator@0.3.0` is advisory
  and lenient — it grades generic syntax/density/tier, not strict structural correctness
  or any `unsorry` domain schema (a file with appended unbalanced-bracket garbage still
  validated at Platinum). The load-bearing coordination checks live in `tools/gate_b`.

- **Observability gaps in coordination trials (item (c)).** Live-trial first-push-wins
  arbitration tallies are visible only in supervisor stderr (not committed); rejected
  pushes leave no commit. The mechanism is reproducible via `--self-test`, but adding an
  on-repo collision-event log would make the live behaviour independently auditable. The
  metrics prose also overstates one specific reaper dispatch run (`00:44Z`); the
  underlying live-claim safety is still sound.
