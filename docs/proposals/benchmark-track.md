# Benchmarking unsorry (issue #5643) — Research & Plan

> **Status:** Proposal · **Tracking issue:** #5643 · **Date:** 2026-06-24
>
> Research deliverable for issue #5643. The implementation breakdown — ratifying ADR-078/080/081, the skeleton-package intake (`tools/intake/skeleton_validate`), ADR-078 registered benchmark targets, the `registered-targets.json` index, the unsorry-guild goals page, and the `run.sh --goal` flow — is tracked under **#5643**.
>
> **One correction to §7 of the body:** the new benchmark-track ADR is **ADR-092+** (verified live at implementation), *not* ADR-091 — ADR-090 (Periodic Housekeeping) and ADR-091 (validator PR #4852) are already taken.

> **Scope note:** this report covers two questions the issue conflates — (a) **SWE-bench Lite** and (b) **historical hard / recently-solved problems** — which sit on opposite sides of unsorry's founding soundness line, so they are treated separately below. Every section was produced by a parallel research workflow and an adversarial verification pass; the historical-hard dimension (Section 4) was re-researched after an initial agent failure and re-verified at high reliability (all load-bearing claims confirmed).

---

## 1. Executive summary & recommendation

**Headline:** SWE-bench Lite does **not** fit unsorry and cannot be made to fit without building a second, weaker product that deliberately sits *outside* the trustless commons. Lean/formal-math benchmarks fit unsorry **natively** — a benchmark item is already exactly the shape unsorry eats (a Lean statement ending in `sorry`). So the issue's two asks resolve as:

- **SWE-bench Lite → out-of-scope by design** (not merely by missing tooling). Its test-based oracle is the exact "gameable oracle" the founding plan ranked #3-of-9 and rejected (`docs/proposals/distributed-research-swarm-plan.md:149,165`), and ADR-080's non-negotiable gating invariant explicitly excludes test-based software from the commons (`docs/adrs/ADR-080-...:71-89`). unsorry's resolve rate on SWE-bench Lite *today* is ~0% by construction — it emits Lean proofs, not Python patches. Use it only as a labelled external reference point ("the shape we deliberately did not pick").
- **Lean/math benchmarks → in-scope-soon.** PutnamBench (672 Lean 4 problems, Apache-2.0) and miniF2F (488, MIT) are already named as intended themes in the swarm's own sourcing prompt (`swarm/prompts/source.md:9`). The mapping is near-trivial in *form*; the real work is mathlib-pin re-elaboration, the four intake gates, and false-statement filtering.

**Single recommended first milestone (Milestone 1):** Wire a **~50-problem PutnamBench subset as a segregated benchmark track**, ingested as flat open goals through the *already-built* `tools/sourcing/gen_triples.py` seam, and report **"verified pass@k, zero false positives"** — a strictly stronger guarantee than SWE-bench's unit-test pass. This proves the whole loop (import → intake gates → claim → Gate A kernel re-verify → segregated scoring) end-to-end with no net-new admission infrastructure, behind one ADR + SPEC + TDD on a feature branch.

**Critical caveat the maintainer must decide first:** the *only* pre-existing written benchmark intent in the repo (Phase-3 Thread G, `docs/proposals/phase3-roadmap.md:39-45`) benchmarks the **AISP coordination notation**, not the solver. A benchmark of the **proof-solving swarm itself** (the subject of issue #5643) is genuinely **un-planned** and must originate its own ADR. Do not assume Thread G covers this.

---

## 2. The domain-fit problem — SWE-bench Lite vs a Lean-proof swarm

**What SWE-bench Lite is** (all confirmed by the adversarial pass): 300 test + 23 dev instances drawn from 11 of the 12 original Python repos (Django, sympy, scikit-learn, matplotlib…), selected from 2,294 issue-PR pairs ([swebench.com/lite.html](https://www.swebench.com/lite.html), [HuggingFace princeton-nlp/SWE-bench_Lite](https://huggingface.co/datasets/princeton-nlp/SWE-bench_Lite)). A model gets a `problem_statement` + repo at `base_commit` and must emit a **unified-diff code patch**. Scoring is **test-based in a Docker harness**: "resolved" iff all `FAIL_TO_PASS` tests flip green **and** all `PASS_TO_PASS` stay green, with a hidden `test_patch` supplying the tests ([SWE-bench/SWE-bench](https://github.com/SWE-bench/SWE-bench)). MIT-licensed, freely available. Top public resolve ~60% (Claude Opus 4.6 ~62.7% as of 2026-06-22); the long-tail "~51 models, mean ~25.5%" figure could **not** be independently verified (leaderboard returned 403) — treat as indicative only. The verdict does not depend on it.

**Why it does not fit — three layers, all verified:**

1. **Wrong domain / missing capability.** unsorry's loop claims a Lean goal, emits Lean tactic text, and is verified by the Lean kernel via Gate A. SWE-bench needs a fundamentally different agent: read a Python repo, localise a bug, edit source, run `pytest` in a per-repo Docker image. unsorry has *none* of that — no patch-apply, no Python test runner, no Docker eval harness, no code-localisation agent.

2. **Domain-neutrality does not rescue it.** ADR-080 already generalises the engine, but its gating invariant admits a domain **only** if every contribution is re-checkable by a cheap, deterministic, **kernel-grade** verifier "with no human and no lab in the correctness path" (`ADR-080:71-75`, verified verbatim). Clause 2 explicitly contrasts *formal* SW/HW verification (proof-checked → admitted, e.g. the Lion microkernel) against **test-based software** ("founding rank #3, tests are a gameable oracle" → rejected, `ADR-080:79-82`). SWE-bench is precisely the test-oracle case. ADR-052 could host it only at the **SCORED** tier, which `ADR-080:90` demotes to **advisory-only** and bars from the merge-trust path (verified).

3. **Test-pass is a weaker oracle than a proof.** Green tests can be overfit/gamed; the founding plan states "green tests do not prove correctness, so a swarm can overfit the suite" (`distributed-research-swarm-plan.md:165`, verified). Admitting it would break the "commons cannot be poisoned" guarantee.

**Verdict:**

| Track | Verdict |
|---|---|
| SWE-bench Lite as a goal class flowing claims→Gate A→main | **Out-of-scope-for-now (by deliberate design)** |
| SWE-bench Lite as a *standalone, explicitly-weaker* benchmarking harness, labelled non-trustless-commons per ADR-080 clause 3, never wired to claims/Gate A/leaderboard/auto-merge | **Major-effort, only if leadership wants a marketing number** — a second product (Docker-per-repo harness, patch-apply, pytest runner, code-edit agent), reusing *nothing* of the Lean loop |
| Formal SW/HW verification (spec→impl refinement with proof obligations, e.g. Lion) as the "software" direction instead | **In-scope by design** — this is the ADR-080-admissible software shape |

**Recommendation:** Do **not** adopt SWE-bench Lite as an unsorry target. If a software story is wanted, pursue the formal-verification shape, not test-pass repair. Cite SWE-bench in platform-generalisation writeups as the deliberately-excluded contrast.

---

## 3. Recommended benchmark suites that DO fit (tiered)

Every suite below shares unsorry's atomic unit — a Lean theorem statement to be closed — so each projects onto `goals/<id>.lean` (statement + `sorry`) + `goals/<id>.aisp` (open record). The discriminators are **mathlib-pin alignment**, **false-statement risk**, and **license**. unsorry's pinned context is `leanprover/lean4:v4.30.0` + the mathlib rev in `lake-manifest.json` (verified); **every** import must be re-elaborated against *this* pin, not the benchmark's own (newer) toolchain — name/API drift is expected and is what the type-check gate catches. SOTA on the top suites is near-saturated at the *frontier*, so treat them as a **graded difficulty substrate (difficulty 1–5)**, not a scoreboard unsorry will "top."

**Tier 1 — best first wire-up: PutnamBench**
- 672 manually-crafted, human-verified Lean 4 formalizations, Putnam 1962–2025; **Apache-2.0** on the Lean subset; a real maintained Lean/Lake project ([trishullab/PutnamBench](https://github.com/trishullab/PutnamBench), [arXiv:2407.11214](https://arxiv.org/abs/2407.11214)). *Read the count at ingestion time* — the repo grows (some papers cite 640/644/660; live is 672).
- Already named in `swarm/prompts/source.md:9`. Undergraduate competition math → naturally difficulty 3–5.
- Frontier near-saturated (Aleph ~668/672; Seed-Prover 1.5 ~581/672, *medium confidence, point-in-time vendor figures*) — a difficulty source, not headroom.
- Caveat: Putnam problems are often **not naturally decomposable**, so admit as atomic single-`sorry` goals (relevant to credit, §5).

**Tier 2a — miniF2F-Lean4** (244 valid + 244 test = 488; [yangky11/miniF2F-lean4](https://github.com/yangky11/miniF2F-lean4), MIT). The field-standard pass@k yardstick → externally comparable numbers. Import `valid` first as a difficulty ramp; hold `test` for headline comparability. **Mandatory pre-filter against published errata**: "miniF2F-Lean Revisited" ([arXiv:2511.03108](https://arxiv.org/abs/2511.03108), OpenReview KtaHv0YUyh) found >50% formal/informal discrepancies and **16 unprovable statements**, producing miniF2F-v2. (The raw finding mis-dated this as "April 2025"; the verifier corrected it to **Oct/Nov 2025** — i.e. the hazard is even more recent than first stated.)

**Tier 2b — CombiBench** (100 Lean 4 combinatorics problems; [moonshotai.github.io/CombiBench](https://moonshotai.github.io/CombiBench/), [arXiv:2505.03171](https://arxiv.org/abs/2505.03171)). High strategic value: combinatorics is *thin* in mathlib, so these are genuinely hard and under-served (best model solved only 7/100), differentiating unsorry from the saturated algebra/arithmetic space. Note: its Fine-Eval "fill-in-the-blank" items may need reshaping into a plain `:= sorry` obligation.

**Tier 3 — defer:** ProofNet (371 undergrad pure math; **Lean 3 original**, needs port; [arXiv:2302.12433](https://arxiv.org/abs/2302.12433)); FIMO (149, Lean 3, extremely hard — DeepSeek-Prover solved 5/148, low yield; [arXiv:2309.04295](https://arxiv.org/abs/2309.04295)); Lean-Workbook/Lean-Workbook-Plus (~57k+83k autoformalized, **Apache-2.0 on the HF dataset** — note the *paper* artifact is CC-BY-NC-ND, pull from HF not the paper; ~6.5% false → thousands of bad statements, ingest only a re-verified subset; [arXiv:2406.03847](https://arxiv.org/abs/2406.03847)); FormalMATH (5,560, autoformalized; [arXiv:2505.02735](https://arxiv.org/abs/2505.02735)).

**Explicit non-fit: miniCTX** ([arXiv:2408.03350](https://arxiv.org/abs/2408.03350)) — its whole point is multi-file project context, which contradicts unsorry's self-contained `import Mathlib` single-file goal. Skip.

**Ingestion/conversion work (per suite):** extract each `theorem … := sorry` → rewrite to `import Mathlib` + statement → **re-elaborate under v4.30.0 pin** (fix API drift) → run the four existing gates (`check_absence`, `lake build UnsorryGoals`, `check_triviality`, provable+skeptic) → `gen_triples` with slug + theme + difficulty. **Confirm each suite's license per-repo before redistributing statements into `goals/`** — do not assume.

---

## 4. Historical-hard / recently-solved track  *(verified — overall_reliability: high)*

The issue's phrasing invites a conflation the plan must avoid: **"the project is solved" ≠ "this is one closeable goal."** A goal is ONE self-contained `import Mathlib` file ending in a single `sorry`. So "recently solved hard problems" split cleanly:

**Sourceable now (single-`sorry` goals, near drop-in):**
- **jsm28/IMOLean** — recent IMO problem *statements* (2006+, incl. IMO 2024 P4, IMO 2025 P2), each already "a single theorem using `sorry`", `import Mathlib`, explicitly authored as solver challenges → the **cleanest format match** to unsorry. ([jsm28/IMOLean](https://github.com/jsm28/IMOLean))
- **mathlib4 IMO archive** (~32+ problems) — ships *proofs*; re-`sorry` the obligation to mint a challenge goal.
- **PutnamBench upper tail** — 640 Lean 4 theorems (paper count; the live repo has grown — *read it at ingest*), self-contained over Mathlib with `sorry`; ingest the harder subset at difficulty 4–5. ([arXiv:2407.11214](https://arxiv.org/abs/2407.11214))
- **CombiBench pure-proof items** (~55%) — `import Mathlib`, self-contained, directly ingestable; covers all IMO combinatorics since 2000 (except 2004 P3). The ~45% fill-in-the-blank items need an answer-abbrev convention first. ([arXiv:2505.03171](https://arxiv.org/abs/2505.03171))
- **DeepMind Formal Conjectures** — hundreds of famous/recently-solved problems (incl. Erdős, e.g. #266 = Kovác–Tao 2024) as one file per problem ending in `sorry`; needs a one-time **import normalisation** (`FormalConjectures.Util.ProblemImports` → `import Mathlib`, strip/alias repo-local `answer(...)`/`@[category]` elaborators). ([google-deepmind/formal-conjectures](https://github.com/google-deepmind/formal-conjectures))
- **Hand-extracted statement-only landmarks + leaf lemmas** — the *top-level statement* of finished projects re-`sorry`ed (PFR's `PFR_conjecture`, FLT-for-regular-primes are safest — supporting defs already upstream), and individual **leaf lemmas** from completed projects (Carleson's ~180 blueprint lemmas, PFR's Shannon-entropy inequalities) → the **most defensible "single closeable hard goal" content**.

**Aspirational only (NOT a single goal — full multi-file projects):**
- **PFR/Marton** (teorth/pfr, ~1772 commits + the whole Shannon-entropy library), **Liquid Tensor Experiment** (mathlib3-era, pre-v4.30.0), **sphere packing dim 8 / E8** (math-inc; ~180k lines final, defs absent from upstream mathlib), **Carleson** (fpvandoorn/carleson, ~180-task project), **FLT** (ImperialCollege, still *incomplete*, funded to 2029). Proving any in one goal = reproducing the project.
- **Out of the Lean track entirely:** **BB(5)** (machine-checked in **Coq**, not Lean), **Kepler/Flyspeck** (HOL Light/Isabelle), **FrontierMath** (Epoch deliberately did *not* formalize in Lean — uses one-off numeric verifiers). Document these as out-of-scope to pre-empt mis-scoped contributions.

**Track design:** a segregated, **difficulty-5-weighted cohort** using the *existing* `.aisp` difficulty field + a track/source tag, with an explicit policy that its expected-low solve rate is **quarantined from the main leaderboard and per-agent stats** (consistent with conforming new mechanisms to the existing attribution canon).

**Two format decisions this track forces** (→ §9 open questions): (a) does the single-`sorry` rule permit an accompanying `abbrev answer := …` — needed for ~60% of Putnam and ~45% of CombiBench "determine-the-answer" problems — or must those be reformulated/excluded? (b) is a small self-contained def-preamble allowed (making sphere-packing/Carleson *statements* ingestable), or does any non-mathlib preamble disqualify a goal as not self-contained?

**Verification caveats to carry:** sphere-packing's exact completion date/line-count is the most uncertain detail (structural verdict unaffected); and two sub-claims to confirm in-tree before relying on them — "FLT-for-regular-primes is in mathlib's `Archive/`" and "IMO 2024 P5 in the archive" (the standalone formalizations are confirmed; their mathlib-archive *paths* were not).

## 5. Integration architecture — the intake seam

A benchmark batch becomes swarm-provable work by becoming the canonical **triple**: `goals/<id>.lean` (`import Mathlib` + `theorem … := by sorry`, type-checks under the pin) + `goals/<id>.aisp` (SPEC-003-A record) + `backlog/<id>.md` (evidence). The `.aisp` carries header `𝔸5.1.goal.<id>@DATE`, `γ≔unsorry.goal`, and sections `⟦Ω:Goal⟧{id;phase≜prove;status≜open;difficulty}`, `⟦Σ:Source⟧{src≜backlog/<id>.md}`, `⟦Γ:Deps⟧`, `⟦Λ:Artifact⟧{lean;sha≜∅;aff≜-20}`, `⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩` (all verified against `SPEC-003-A` and `gen_triples.py:68-93`).

There are **two seams**, and the choice between them is the central architectural decision:

**Path A — BUILT and usable today (recommended for Milestone 1):** drive `tools/sourcing/gen_triples.py` once per problem (`--slug --lean-sig --statement --difficulty --validate`) to emit Gate-B-clean `status≜open` triples; batch **≤50 per `chore(sourcing):` PR** (the hard cap, verified `SKILL.md:117`, `ADR-060`); auto-merge queues them; the swarm claims/proves via the normal loop; Gate A re-verifies every proof. This treats the benchmark as **flat independent atoms** — exactly what sourcing produces — giving clean per-goal pass/fail.
- **Important correction from verification:** `gen_triples.py` only *assembles* and (with `--validate`) Gate-B-checks the triple. It does **not** itself run absence / type-check / triviality / skeptic. A benchmark importer must invoke `check_absence` and `check_triviality` (and a type-check) **separately**, or those screens are bypassed. Build the importer to run all four gates explicitly.
- **Attribution correction:** sourcing credit is read from the **git add-author of the earliest commit that added `goals/<id>.aisp`** (`generate.py:1461+`), *not* from a schema field and *not* directly from `UNSORRY_SOLVER`. `UNSORRY_SOLVER_NAME/EMAIL` sets the git **commit identity** that add-author then resolves via `contributor-aliases.json`. A CI benchmark harness must therefore **set the git author identity** on ingest commits, not just an env var, to keep benchmark credit separable from organic credit.

**Path B — DESIGNED but NOT BUILT (required only for structured/decomposed targets):** the curated **skeleton package** + `python3 -m tools.intake.skeleton_validate <dir>` admission gate (SPEC-081-A): a `skeleton.aisp` manifest (`top≜; supplier≜; domain≜math|software|construction; toolchain≜; mathlib≜`), per-obligation `goals/<id>.{aisp,lean}`, and `decompositions/<parent>.<supplier>.aisp` edges; exit 0/1/2 mirroring Gate B; admit only if the top statement type-checks (no sorry), every leaf is a well-formed open goal, edges are sound/acyclic/rooted-at-top, the verifier context resolves, and **curated-target provenance** is present (vetted supplier, not self-minted).
- **Load-bearing blocker (confirmed):** `tools/intake/` **does not exist**, and **ADR-080, ADR-081, SPEC-081-A are all Status: Draft**, gated on founder ratification. Path B requires implementing `skeleton_validate.py` *and* ratifying ADR-080/081 first. The large landmark formalizations of §4 are the only things that *need* Path B — so for benchmarking, **Path A is the answer** and Path B is explicitly deferred.

**How a benchmark maps onto the intake contract:** a benchmark is a vetted external curated batch, which maps cleanly onto ADR-081's "curated-target provenance" requirement (ADR-080 declares unsorry domain-neutral for any kernel-grade-verifiable domain — math qualifies). Ingested as flat atoms via Path A, benchmark goals still pass the same triviality screen and Gate A kernel re-verification, giving an **honest measure of what the swarm can actually prove**.

**Segregated benchmark track (required):** tag benchmark goals into their own cohort — either a `bench≜<suite>` field on `goals/*.aisp` + proof-runs, or a separate `proof-runs/` namespace — so benchmark pass-rate (a *model/method* metric) does **not** inflate the difficulty-weighted contributor leaderboard or dispatch credit (a *fairness* metric). ADR-079 is precedent that a distinctly-tagged cohort can coexist without changing what scores (*ADR-079 is Status: Proposed — verify before treating as ratified*). `tools/leaderboard/generate.py` will need a new segregation filter so benchmark proofs are excluded from `credited_contributors`/`_score`.

**sponsor-registered / seedkit are wrong fits:** seedkit mints *born-proved* fixtures (the proof is attached) — not a benchmark, which must be *open*. ADR-078 sponsor-registered targets **zero out self-dealing** (skeleton author ≠ discharger; self-registered earns nothing) — so a benchmark ingested as a sponsor target by the same party running the swarm earns zero credit *by design*. Keep credit and capability measurement distinct: use Path A flat-atom sourcing, segregated cohort.

---

## 6. Metrics & scoring

**Score a benchmark run as "verified pass@k, zero false positives" — a strictly stronger guarantee than test-based eval or self-reported pass@k.** Every counted success is **kernel-verified** by Gate A: axiom audit (`Lean.collectAxioms` over the *elaborated environment*, not source text — so renaming/whitespace/notation tricks cannot evade it), `leanchecker` replay, and **ADR-011 statement-binding** (the merged declaration's elaborated type is `isDefEq` to the goal's, so "proved" means "proved *this* statement"). ADR-052 already classifies the Lean adapter as the **VERIFIED tier** ("one accepted deterministic result may auto-merge"), which is exactly what makes "verified pass@k" honest. Pair every reported number with the literal **"0 false positives (kernel-verified)"** claim — which SWE-bench (incomplete test oracle) and self-reported pass@k cannot make. *Status caveat: ADR-052 and ADR-079 are Status **Proposed**, not Accepted; ADR-011 and ADR-035 are Accepted.*

**Estimator:** use the Codex/HumanEval unbiased estimator `pass@k = E[1 − C(n−c, k)/C(n, k)]` over `n ≥ k` independent attempts per goal under a fixed budget, `c` kernel-accepted. **Applicability gap (from verification):** current `proof-runs/` telemetry records `attempts` as a *single integer per run*, not `k` fixed-budget samples per goal — so computing unbiased pass@k requires the harness to **fix the sampling protocol** (log each attempt as a distinct, budgeted sample), not just re-read existing telemetry. miniF2F's "10-min wall cap for pass@1" is a *per-paper convention*, not a benchmark invariant — the track must pick and **document its own fixed budget**.

**Anti-gaming is already structural:** ADR-011 defeats the "restate as `True`/vacuous" vector; ADR-035's `check_triviality.py` rejects items closable by the `rfl/decide/norm_num/omega/simp/aesop/ring/linarith/tauto` battery (deliberately *excluding* `nlinarith/positivity/field_simp/gcongr`); ADR-081's skeleton-validate rejects ill-formed imports at the door. **Side effect to report honestly:** easy benchmark items closable by the triviality battery will be *filtered out before the swarm attempts them*, biasing the measured set toward harder items — **report the rejection rate as its own benchmark signal**, don't hide it.

**Two residual soundness limits to disclose:**
1. **Provenance is spoofable, not kernel-enforced.** The kernel guarantees the *proof* is correct, not *which model* produced it. "Model X scored verified pass@k=Y" is only as trustworthy as ADR-023/037 corroboration. The kernel-true claim is airtight; the model-attribution claim is not — consider reporting whole-swarm aggregate pass@k, or per-model only with the caveat stated.
2. **Statement-binding ≠ formalization fidelity** (ADR-011's own residue). "0 false positives" is true *relative to the imported Lean statements*, contingent on those statements faithfully capturing the originals. A wrong-but-agreed formalization passes — which is exactly why the **false-statement filter (§3, miniF2F-v2 errata) is mandatory**, and why **benchmark contamination/memorisation** (public miniF2F solutions likely in training data) must be disclosed: high pass@k may reflect recall, not reasoning.

**Leaderboard mapping:** benchmark cohort on its own board panel; excluded from `_score` (= `difficulty_points*100 + verified_proofs*25 + dispatch_points*100`; note the scored field is `verified_proofs`, the `credited_proofs` label is doc-string only). Leaderboard regen is ~10 min single-pass (ADR-082), so a benchmark cohort adds negligible reporting cost.

---

## 7. Protocol-conformant delivery plan

This is a "significant decision touching the `goals/` contract" → full protocol stack (ADR + SPEC + TDD + feature branch + Gate B + changelog + release). **It cannot land as an ad-hoc script.**

**ADRs to write** (next-free numbers are **ADR-091 / SPEC-091-A** — highest existing is ADR-090/SPEC-090-A, verified; but the swarm races ADR numbers on the unprotected `claims` branch, so **claim the number first and be ready to renumber to the next free NNN on collision**, updating all refs in the ADR/SPEC/index/roadmap):
- **ADR-091 — Solver-Proof-Benchmark-Track** (proposed title). Decision: ingest external Lean benchmark suites as a *segregated* flat-atom goal cohort via Path A; score as verified pass@k; exclude from contributor leaderboard. House style: metadata table (Decision ID / Initiative / Proposed By / Date / Status: **Proposed**) + WH(Y) Context, mirroring `ADR-090`.
- *(Optional, only if Path B is ever wanted)* a **separate** ADR/SPEC to implement `tools.intake.skeleton_validate` per SPEC-081-A — but that depends on **ratifying the Draft ADR-080/081 first**, so keep it out of Milestone 1.

**SPEC to write:** `SPEC-091-A-Solver-Proof-Benchmark-Track.md` under `docs/adrs/specs/`, with **Goal / Behaviour / Verification** sections, specifying: the importer CLI, the four-gate enforcement, the `bench≜` cohort tag, the pass@k sampling protocol + fixed budget, and the leaderboard segregation filter. If it touches `/swarm/` or gate surfaces (CODEOWNERS, ADR-019), add the explicit human-code-owner-review note as SPEC-090-A does.

**TDD plan** (tests first; `python3 -m pytest tools -q`):
- `tools/sourcing/import_benchmark.py` (new module, reuses `gen_triples`; **not** seedkit) — tests: extract→rewrite→re-elaborate→four-gate funnel→triple emission; deterministic slugging; `bench≜` tagging; clobber-refusal (ADR-018 create-only).
- `tools/benchmark/` scoring — tests: unbiased pass@k estimator over fixture run records; segregated-cohort aggregation; **leaderboard exclusion** (benchmark proofs absent from `credited_contributors`/`_score`); determinism so Gate-B `--check` doesn't churn.
- Reuse `tools/gate_b/` and `tools/leaderboard/` fixtures.

**Feature branches** (one logical change each; no direct commits to `main`; squash auto-merge on green Gate A + Gate B): `feature/solver-proof-benchmark-track` (ADR+SPEC), `feature/benchmark-importer` (importer + tests), `feature/benchmark-scoring` (pass@k + leaderboard segregation).

**Gate A/B implications:** the *tooling* is pure Python → Gate A trivially green (no Lean). The *ingested goals* must type-check under the pin (the importer's type-check gate ensures Gate-B-clean triples). Ensure no generated `leaderboard.*`/metrics JSON is bundled into the source-only ADR PR (they churn/conflict — ADR-036 post-merge refresh).

**Changelog:** add `changelog.d/added-solver-proof-benchmark-<id>.md` (category `added`, unique slug with PR/agent id); **do not** edit `CHANGELOG.md` directly. Release per the release-process: fold fragments via `python3 -m tools.changelog --release` in a separate `docs(vX.Y.Z)` PR, then **manual** tag + `gh release create` (push tag first; `--target shortsha` 422s).

**Run-record evidence:** produce `docs/metrics/<benchmark>-run-001.md` + `.json` mirroring the `phaseN-run-NNN.md`+`.json` convention, recording per-run audit evidence (work-unit id+version, toolchain/mathlib rev, model+effort, result status, artifact sha) so pass@k is replayable.

**README/doc accuracy:** README has **no** benchmark-harness claim (only the philosophical "no benchmark to game" at `README.md:59`); CONTRIBUTING has none — so **README-accuracy exposure is minimal**; add a short "Benchmark track" note only once Milestone 1 lands.

---

## 8. Phased roadmap

**Milestone 1 — smallest end-to-end slice that proves the loop (recommended start).**
*Scope:* ~50 PutnamBench problems → flat open goals via Path A (`import_benchmark.py` → 4 gates → `gen_triples` ≤50/PR) → segregated `bench≜putnam` cohort → swarm claims/proves → Gate A re-verifies → report **verified pass@1 + pass@k (k∈{1,4,8})** with "0 false positives" and the triviality-rejection rate.
*Why:* uses only built seams; no skeleton-validate, no ADR-080/081 ratification; proves import→intake→claim→kernel-verify→segregated-scoring.
*Effort:* ADR+SPEC (~1 PR), importer+tests (~1), scoring+leaderboard segregation (~1), plus a bounded measured run. **Throttle PR-creation rate** to the Gate A namespace-verifier lanes (ADR-058) and the ~20 in-flight cap so the benchmark batch doesn't starve the organic queue.

**Milestone 2 — comparability + breadth.** Add **miniF2F** (`valid` first, errata-filtered against miniF2F-v2; hold `test` for headline numbers) → externally citable pass@k. Add **CombiBench** as a high-value, under-served combinatorics cohort.

**Milestone 3 — porting track (only if yield justifies).** Lean-3 suites (ProofNet, FIMO) behind a validated Lean-3→Lean-4 + mathlib-pin port; re-verified subsets of Lean-Workbook/FormalMATH.

**Milestone 4 — historical-hard / recently-solved sourcing.** Wire Formal Conjectures / Erdős-style self-contained statements as a curated supplier (provenance-vetted, provable+skeptic enforced).

**Milestone 5 — structured targets (only if needed, large).** Implement `tools.intake.skeleton_validate` (SPEC-081-A) **after** ADR-080/081 are ratified, to admit decomposed landmark targets. This is the only path to the large formalizations of §4 and is explicitly out of scope for benchmarking-as-such.

---

## 9. Risks, open decisions, and questions for the maintainer

**Decisions needed before Milestone 1:**
1. **Confirm the subject.** Issue #5643 is about benchmarking the **proof-solving swarm**, which is *un-planned* — the only written intent (Phase-3 Thread G) benchmarks the **AISP notation**. Confirm this is a new capability ADR (ADR-091), not Thread G.
2. **Preserve benchmark naming?** Keep `putnam_1962_a1`-style ids for external comparability, or re-slug to kebab-case? Affects citability against published leaderboards.
3. **Per-model or whole-swarm pass@k?** Given spoofable provenance (the kernel proves *correctness*, not *authorship*), decide whether to report per-model cohorts (with the caveat) or only swarm-aggregate.
4. **Cohort mechanism:** `bench≜` field on `.aisp` vs separate `proof-runs/` namespace — and the corresponding `generate.py` segregation filter.

**Risks (verified):**
- **mathlib-pin drift** is the dominant unknown and the main ingestion cost — benchmark repos pin newer toolchains than v4.30.0, so a large fraction of statements won't elaborate as-is. Type-check yield against the old pin is unmeasured until you try.
- **False/misformalized statements stall the swarm** (matches the existing `integer_triple_descent` / `positive_of_smaller_descent_target` false-goal failure modes in memory). The provable+skeptic gate and errata cross-check are **mandatory and costly per item**.
- **Triviality filtering biases the measured set** toward harder items (report the rejection rate separately).
- **Gate A throughput** (namespace lanes, ~20 in-flight) is the capacity ceiling — throttle batch size and PR rate.
- **Contamination/memorisation** — public benchmark solutions likely in training data; disclose when reporting.
- **Draft/Proposed status** — Path B (skeleton-validate) and its parents (ADR-080/081, SPEC-081-A) are **Draft**; ADR-052/079 are **Proposed**. Verify status before treating any as ratified policy.
- **ADR-number race** on the `claims` branch — claim 091 first, renumber on collision.

**Open questions:**
- Exact mathlib rev in `lake-manifest.json` and its age vs PutnamBench/miniF2F current toolchains (determines real type-check yield) — *not yet read*.
- Is there an existing errata cross-check mechanism, or must the importer build one? (Build one.)
- Does the agent loop need to log every attempt as a distinct budgeted proof-run to make unbiased pass@k computable? (Yes — current `attempts`-as-integer telemetry is insufficient.)
- Does decomposition (ADR-009) count a benchmark goal solved-by-sub-lemmas as a pass@k success, or only a single-module direct proof? (miniF2F scores whole-statement pass — decide and document.)

**Sources (external):** [swebench.com/lite.html](https://www.swebench.com/lite.html) · [HuggingFace SWE-bench_Lite](https://huggingface.co/datasets/princeton-nlp/SWE-bench_Lite) · [SWE-bench GitHub](https://github.com/SWE-bench/SWE-bench) · [trishullab/PutnamBench](https://github.com/trishullab/PutnamBench) ([arXiv:2407.11214](https://arxiv.org/abs/2407.11214)) · [yangky11/miniF2F-lean4](https://github.com/yangky11/miniF2F-lean4) · [miniF2F-Lean Revisited arXiv:2511.03108 / OpenReview KtaHv0YUyh](https://openreview.net/forum?id=KtaHv0YUyh) · [CombiBench arXiv:2505.03171](https://arxiv.org/abs/2505.03171) · [ProofNet arXiv:2302.12433](https://arxiv.org/abs/2302.12433) · [FIMO arXiv:2309.04295](https://arxiv.org/abs/2309.04295) · [Lean-Workbook arXiv:2406.03847](https://arxiv.org/abs/2406.03847) · [FormalMATH arXiv:2505.02735](https://arxiv.org/abs/2505.02735) · [Lean-4 breakthroughs survey](https://www.cs.virginia.edu/~rmw7my/Courses/AgenticAISpring2026/Major%20Breakthroughs%20in%20Lean%204-Based%20Auto-Formalized%20Mathematics.html) · [frenzymath.com conjecture](https://frenzymath.com/blog/conjecture/) · [Harder–Narasimhan formalization arXiv:2509.19632](https://arxiv.org/abs/2509.19632)

**Key repo anchors:** `docs/proposals/distributed-research-swarm-plan.md:149,165,188` · `docs/adrs/ADR-080-...:71-90` · `docs/adrs/ADR-081-...:29-37,90-105` · `docs/adrs/specs/SPEC-081-A-...` · `docs/adrs/ADR-052-...:23-26,78-83,126-128` · `docs/adrs/ADR-011-...:14,26-27,38-39` · `docs/adrs/ADR-035-...` · `docs/adrs/ADR-058-...:84-114` · `docs/adrs/ADR-078-...:27-45` · `docs/adrs/ADR-060-...:24-31,87-90` · `docs/adrs/ADR-082-...:21-23` · `tools/sourcing/gen_triples.py:61-93,158-164,253-260` · `tools/leaderboard/generate.py:1024-1031,1461-1535` · `swarm/prompts/source.md:9-27` · `docs/proposals/phase3-roadmap.md:39-45,53` · `CHANGELOG.md:677` · `README.md:59` · `lean-toolchain` (v4.30.0) · `lake-manifest.json` · next-free `ADR-091/SPEC-091-A`.