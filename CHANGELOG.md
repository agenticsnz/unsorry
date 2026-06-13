# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- Gate A kernel replay (`leanchecker`) OOM-killed the runner again (exit 143, ~4 min in) once the library grew by the `euclid-perfect-numbers` recompose modules (#370): leanchecker holds ~all of mathlib resident, and that peak RSS crept past the 7 GB standard-runner limit. Chunk size does not move the ceiling (the cost is the mathlib image, not the few library oleans per chunk), so the gate-a job now allocates **12 GB of swap** before the replay step, letting leanchecker page cold olean regions rather than OOM. The job uses ~10 of its 60-min budget, so the extra paging is comfortably absorbed. The recompose proof itself was sound (build `--wfail` + axiom audit + ADR-011 binding all passed); only the kernel-replay step was resource-starved.

### Added

- ADR-031/SPEC-031-A: a staged, two-track roadmap to **Freek #50 ("The Number of Platonic Solids")** (issue #365). Scoping established that the accepted bar is HOL Light's `PLATONIC_SOLIDS` — an existence-biconditional over ℝ³ convex polytopes — and that mathlib lacks essentially the whole substrate (no Euler polyhedron formula, no polytope face lattice, no regularity notion, no concrete solids). **Track 1** (swarm now) seeds an *abstract regular-polyhedron* existence-biconditional that reuses the proved `platonic_schlafli_pairs` as keystone (handshake + Euler ⟹ the core; five concrete `(V,E,F)` witnesses for existence) — a labelled **combinatorial/Euler form, explicitly not** the geometric #50. **Track 2** is the faithful ℝ³ port, decomposed into infrastructure milestones (face lattice → Euler–Poincaré → geometric handshake → the five constructions → assembly), gated on mathlib growth / human-sponsored upstreaming. Honesty guardrail: Freek #50's Lean column stays **unclaimed** until Track 2's faithful biconditional passes Gate A. Adds the Track-1 backlog target `platonic-solids-combinatorial`.

## [1.9.0] - 2026-06-13

Headline: **trunk-discipline CI gates** — three new required checks make every PR's kind and scope unambiguous: PR-title conventions (ADR-026), proof/harness scope separation (ADR-027), and the spec-per-ADR protocol-compliance gate (ADR-028); plus a proposed domain-agnostic distributed-workload engine (ADR-030). On the reliability side: the Gate A leanchecker OOM is fixed by chunked-serial replay, decompose is now idempotent (no more re-decomposing a proved tree — the #364 euclid regression), CHANGELOG conflicts are gone via a `merge=union` driver, and the advisory aisp check no longer reddens every PR.

### Added

- Proposed ADR-030/SPEC-030-A: a domain-agnostic distributed-workload engine with a narrow plugin seam (`workunit` schema; `generate`/`verify`/`decompose`/`assimilate`), so the swarm can be reused as a template for crowdsourced verifiable work ("SETI@home for verifiable work") with Lean as the first plugin. Captures the key distinction from SETI/BOINC — self-verifying results need no redundancy — via a verifiability spectrum (`VERIFIED`/`SCORED`/`CONSENSUS`). Status **Proposed** (design target, no implementation yet); deduplication, identity/anti-abuse, coordination-at-scale, and onboarding are called out as separate follow-up decisions.
- Enforced PR-title conventions (ADR-026/SPEC-026-A): the title taxonomy (`tools/repo/pr_labels.py`, the single source of truth) is now a required CI gate — a new `pr-conventions` check fails any PR whose title matches no known shape, so a PR's kind is unambiguous from its title. Accepted shapes are the full Conventional-Commits set (`feat/fix/docs/chore/ci/test/refactor/perf/build`, scope optional, `:` required) plus the swarm shapes (`prove(<goal>):`, `decompose(<goal>):`, `affinity(<goal>):`, `tr(<goal>):`, `converge(<goal>):`, `redteam<n>(<vector>):` — colon required), where `prove(...)` means the theorem **passed** and `decompose(...)` / `affinity(...)` mean it **did not** (split / demoted). The labeler self-creates any missing labels from the table. `CONTRIBUTING.md` and `docs/pr-labels.md` document the canonical trunk-based, one-logical-change-per-PR workflow (a proof is a proof, a fix is a fix). Mixed-content blocking, a harness-regression test, and a protocol-compliance gate are tracked as follow-ups in issue #302.
- Proof/harness PR-scope gate (ADR-027/SPEC-027-A): a required `pr-scope` check rejects any PR that touches **both** the proof surface (`library/`, `goals/`, `translations/`, `decompositions/`, `proof-runs/`) and the harness surface (`swarm/`, `tools/`, `.github/`, `lakefile.toml`, `lean-toolchain`, …); neutral paths (docs, CHANGELOG, README) may travel with either. This keeps a harness regression from hiding inside a proof PR (the #292 class) and untangles the queue — a proof is a proof, a fix is a fix. Pure classifier in `tools/repo/pr_scope.py` with unit tests; fork-safe workflow using the changed-file API.
- Protocol-compliance gate (ADR-028/SPEC-028-A): a required `pr-protocol` check enforces the `docs/protocols.md` spec-per-ADR rule — a newly added `ADR-<n>` must ship with a matching `SPEC-<n>` (in the same PR or already present), and an orphan `SPEC-<n>` is likewise flagged. Only **added** files are checked, so historical unpaired ADRs (001/002/005/022/…) are untouched. Pure classifier in `tools/repo/pr_protocol.py` with unit tests; fork-safe workflow using the changed-file API.

### Fixed

- Decompose is now idempotent (ADR-009, #366): `decompose_goal` refuses to re-decompose a goal that already has a decomposition record (new `has-decomposition` helper + hermetic `test_has_decomposition`). An unblock that re-opened a fully-proved parent for recomposition, followed by a failed recompose, was falling through to *re-decompose* and overwriting the proved sub-lemma goal records back to `open`/`sha≔∅` (the #364 `euclid-perfect-numbers` regression — proofs and index stayed intact so nothing unsound merged, but the records went inconsistent and the parent could not recompose). A failed recompose now falls through to a harmless demote instead. The clobbered euclid records are restored separately in #367.
- Harness commits (proof PRs, claims, telemetry) are now authored as the authenticated GitHub account instead of the operator's ambient git config (ADR-029/SPEC-029-A). On a fresh machine git's default `Your Name <you@example.com>` placeholder leaks into every harness commit, which GitHub cannot link to a profile — the AISP `solver≜` field was correct (it reads `gh api user`), but the commit author was not. `resolve_git_identity` derives the display name and the no-reply email `<id>+<login>@users.noreply.github.com` (links to the account even with email privacy on) and applies them via git's `GIT_AUTHOR_*`/`GIT_COMMITTER_*` variables, so all harness commits inherit it with no per-call-site change. `UNSORRY_SOLVER_NAME`/`UNSORRY_SOLVER_EMAIL` override it; with no resolvable identity it fails soft to local git config rather than blocking a proof. Self-tested by `test_git_identity_resolution`.

- Concurrent PRs no longer conflict on `CHANGELOG.md`. A `.gitattributes` `merge=union` driver makes git auto-combine additions to the shared `[Unreleased]` section on merge/rebase instead of raising a conflict, so the high merge cadence stops forcing a manual CHANGELOG rebase on every other open PR. (Occasional duplicate section headers are tidied at release time.)

- Gate A kernel replay (`leanchecker`) now runs in bounded **serial** chunks instead of one process over the whole library. #294 made replay serial, but the library has since grown past a single leanchecker's memory headroom and the step OOM-killed the runner again (exit 143, ~13 min in — axiom audit clean, so it was resource exhaustion, not a bad proof). Replay now splits the library into `REPLAY_CHUNK_SIZE`-sized chunks run one at a time (never two mathlib images at once), and the gate-a job timeout is widened 40→60 min to absorb the per-chunk reloads. Regression test asserts a large library splits into multiple serial chunks covering every module.

- Proof-run telemetry records (ADR-023/SPEC-023-A) now carry the canonical `⟦Γ:Goal⟧` block, making them valid AISP-5.1 under the generic upstream `aisp-validator` (ADR-003). Proof-runs were the **only** record type omitting `⟦Γ⟧` — one of the five required blocks Ω/Σ/Γ/Λ/Ε that goals and decompositions already carry — so the upstream validator rejected every run with `error -3` (missing block). That was the real cause of the `aisp-advisory` drift (not the `⟦Δ:Lesson⟧` block, as first suspected: a plain `proved` run with no lesson block also failed). A rendered record now validates VALID (δ 0.77→0.88, Platinum). New records conform; the three pre-existing records are backfilled separately.

- The advisory `aisp-advisory` check no longer reddens every PR. Its per-record loop validated the whole `.aisp` tree with the pinned upstream `aisp-validator@0.3.0` and aborted (`bash -e`) on the first record the pinned validator rejects (proof-runs missing the canonical `⟦Γ⟧` block — see the fix above), so the job went red on every PR even when the PR did not touch coordination records. The per-record loop is now advisory-only (it logs which records the upstream flags and how many, but never fails the step), while the swarm-contract validation stays strict. Still non-blocking (ADR-003); the in-repo Gate B remains the load-bearing validator. Upstream-drift tracking: #318.

- Regression-locked the #292 class of harness break: a new agent-loop self-test (`test_prove_attempt_log_does_not_trip_guard`) reproduces the real interaction — the repo `.gitignore`, an attempt log written into the proof worktree, and the path guard running over that same worktree — and asserts the guard passes and the log is preserved. This is the coverage that was missing when #292 made the harness's own `prove-attempt-<n>.log` trip its own guard and blocked every proof merge.
- Added an end-to-end `run_proof` smoke (`test_run_proof_mock_provider_smoke`) that drives the real prove orchestration — prompt build, the provider call, the path guard, and the statement-binding emit — with a **mock provider** and a stubbed kernel verify, so it runs hermetically without the Lean toolchain. The mock reproduces the #292 shape (target + a stray root file + the harness attempt log) and the smoke must succeed end to end: target in place, stray cleaned, attempt log ignored. Complements the unit-level guard regression test by exercising the whole `run_proof` path a real proof takes.

## [1.8.0] - 2026-06-13

Headline: **OpenAI-compatible local endpoints + pi-coder config (ADR-025)** — the swarm can now prove against any OpenAI Chat-Completions-compatible server (Ollama / vLLM / LM Studio / a proxy or a local model) via `OPENAI_BASE_URL`, with a `-pi [<model>]` flag that sources the endpoint/key/model from pi-coder's `~/.pi/agent/models.json`. Plus the prove-path-guard fix that had been blocking all proof merges. The sourced target batches in this window are content, not release-worthy on their own, and are listed for the record.

### Fixed

- Prove path guard no longer discards a sound proof over harness or provider litter — a regression that blocked **all** proof merges after the in-worktree attempt log was introduced (#292). The agent loop writes `prove-attempt-<n>.log` into the proof worktree, which `prove_target_only_changed` then flagged as a forbidden path; `prove-attempt-*.log` is now gitignored so the loop's own log is invisible to the guard (and preserved on disk for inspection). Additionally, a root-level untracked scratch file (e.g. the stray `test.lean` some providers, notably gemini, drop beside the repo root) is removed and tolerated. Edits to tracked files and untracked files inside any package/spec/tooling tree remain hard violations, and a proof written into the wrong file still fails the missing-target check — so soundness is unchanged.

### Added

- OpenAI-compatible local endpoints and pi-coder config (ADR-025/SPEC-025-A): the OpenAI provider now honours `OPENAI_BASE_URL` and accepts arbitrary model ids on a custom endpoint, so any OpenAI Chat-Completions-compatible server (Ollama / vLLM / LM Studio or a proxy) can drive proving and translation. A new `-pi [<model>]` flag on `./swarm/agent.sh` sources the endpoint, key, and model from pi-coder's `~/.pi/agent/models.json` by the model name/id (the optional `-pi <model>` argument, else `UNSORRY_MODEL`), via a pure-stdlib resolver `tools/llm_providers/pi_config.py`, and works in both `--prove-local` and coordinated `--prove`. New hermetic tests under `tools/llm_providers/tests/` run in CI (gate-b). Kernel re-verification (Gate A) remains the only trust input, independent of endpoint. Limitation: the `--prove` tool loop needs a function-calling-capable model; translation works on any model.

- Sourced target batches 5–9 (ADR-012) — 17 new open goals, each compounding on already-proved library lemmas; every identity numerically verified before sourcing, type-checked against pinned mathlib (rev c5ea00351c28), and machine-absence-checked:
  - **Faulhaber-in-T** (batch 5): power sums as polynomials in the triangular number T=∑k — `sum-range-sq-triangular-form`, `sum-range-pow-four-triangular-form`, `sum-range-pow-five-faulhaber-triangular`, `sum-range-pow-seven-faulhaber-triangular`. The p=5 and p=7 rungs sum to the power-tower crown (3∑k⁵+3∑k⁷ = 6T⁴).
  - **Fourth-power congruences** (batch 6): `odd-fourth-power-mod-sixteen`, `fourth-power-mod-three`, `fourth-power-mod-five` → root `prime-fourth-power-mod-240` (p>5 prime → p⁴≡1 mod 240) — a depth-2 tree extending the proved 24∣p²−1 chain one power up.
  - **Binomial moments** (batch 7): `sum-range-cube-mul-choose`, `sum-range-fall-mul-choose`, `sum-range-choose-mul-two-pow` — compounding on the proved `sum-range-sq-mul-choose`.
  - **Triangular-number gems** (batch 8): `eight-triangular-add-one-eq-odd-sq`, `consecutive-triangular-eq-square`, `cube-eq-triangular-sq-diff` — compounding on the Gauss sum / Nicomachus.
  - **Compositeness via factorization** (batch 9): `pow-four-add-sq-add-one-factor` → `pow-four-add-sq-add-one-not-prime`, plus `one-add-four-b-fourth-not-prime` — paralleling the proved `not-prime-pow-four-add-four`.
  - The gate dropped four from-memory duplicates already in mathlib (`sum_range_choose_sq`, the Sophie Germain identity, fib partial sums, Cassini) — the ADR-012 Nicomachus discipline working as designed. Board: 24 open / 61 proved / 86 total.

## [1.7.0] - 2026-06-13

Catch-up release folding in the feature and infrastructure work merged since v1.6.2: heterogeneous proof providers (Codex coordinated; Gemini and the OpenAI API local-only), the proof-provenance leaderboard and cross-cycle lesson memory, and two Gate A fixes plus an agent claim-race fix. The sourced target batches and individual proofs in this window are content, not release-worthy on their own, and are listed here only for the record.

### Added

- Cross-cycle lesson memory (ADR-024/SPEC-024-A): a failed or decomposed proof run now records a bounded, sanitised single-line failure *signature* in a `⟦Δ:Lesson⟧` block on its ADR-023 proof-run record, plus a `⟦Λ:Metrics⟧` `lessons≜<n>` count of how many prior lessons were injected into that run. Before each prove attempt, `run_proof` surfaces a goal's most-recent, de-duplicated prior failure signatures into the prove prompt (mirroring ADR-014 dependency reuse), so re-attempts across cycles and across agents avoid known dead ends instead of restarting blind. The whole feature is gated by `UNSORRY_LESSONS` (default on); with it off a run is byte-identical to pre-ADR-024 output, so its benefit can be A/B measured against the captured `lessons` telemetry. The lesson surface is advisory only and never participates in statement hashing, Gate A, proof status, affinity, or candidate ranking; Gate B `GB020` validates the optional fields, and the leaderboard ignores them.

- Fourth sourced target batch (ADR-012) — the **power-sum tower**, a deliberately compounding set where each rung stands on the one below (difficulty 2–4): `sum-range-cube-even` (∑(2i)³ = 2n²(n−1)², a corollary of the proved `nicomachus-sum-cubes`), `sum-range-pow-six-closed-form` and `sum-range-pow-seven-closed-form` (Faulhaber p=6, p=7 — the next rungs above the proved p=2..p=5), and the **crown** `sum-range-pow-five-add-pow-seven` (∑k⁵+∑k⁷ = 2(∑k)⁴, depending on the p=5 and p=7 closed forms — a depth-1 stack within the batch). Every statement type-checks against the pinned mathlib (rev c5ea00351c28), is machine-absence-verified (the `i^6`/`i^7` flags adjudicated against Weierstrass-℘ / elliptic-curve code, not Faulhaber; mathlib carries only the general Bernoulli formula), and every identity was numerically verified before sourcing. Dependency edges (`deps≜`) wire the compounding so gap-selection routes the rungs before the crown. Fulfils cgbarlow's interest in how proofs stack toward harder, higher-value targets.

### Fixed

- Gate A kernel replay (`leanchecker`) now runs serially instead of in parallel chunks (#294). `leanchecker` re-checks every declaration against the kernel and holds ~all of mathlib resident per process, so even the previous `min(jobs, 2)` cap ran two full mathlib images and OOM-killed the standard CI runner — the replay step died with exit 143, intermittently failing roughly half of every PR's Gate A after #264 set `--jobs 4`. Replay now uses one `leanchecker` over the whole library (the axiom audit keeps its parallelism — it was never the part that OOMs); a regression test asserts a single invocation regardless of `--jobs`.

- Prove-mode claim recheck uses `PROVE_CLAIM_CAP` (cap 1), not the translate cap (#242). The post-rejection recheck in `claim_goal` called the translate-cap helper in both modes, so a live rival claim on the same goal could pass the cap-1 check and two agents would double-claim a prove goal (the #184/#185 race, reproduced live). The recheck is now mode-aware; a regression test plants a live same-goal rival claim and asserts prove mode withdraws while translate mode still claims under cap 2.

- Proof retries now remove the agent-generated statement-binding helper from a failed verification attempt before invoking the provider again, preventing the strict provider path guard from misclassifying `*Binding.lean` as a forbidden Codex edit.

- Gate A's regenerated binding obligation (ADR-011/SPEC-011-A) now carries the goal file's top-level `open …` commands, so a goal stated under `open Finset` (bare `range`, batch-3 shape) elaborates in its own namespace context instead of failing with `Unknown identifier`. Same fix mirrored in the agent loop's local self-verify (`write_binding_module`, new `lean-opens` helper); shared parsing in `tools.lean_sig.open_lines`. Surfaced by PR #259 (`sum-range-pentagonal-closed-form`); also unblocks `sum-range-sq-mul-choose`

### Added

- Optional proof provenance, terminal-run telemetry, and deterministic community statistics (ADR-023): newly verified index entries record the GitHub solver, swarm agent, provider, effective model when available, final effort, attempts, and local solve time; append-only `proof-runs/` facts also retain decomposed and terminally failed runs. `python3 -m tools.leaderboard --write` derives leaderboard, success/failure and attempt rates, timing distributions, queue state, difficulty calibration, provider/model and effort-rung efficiency, daily cohorts, and unresolved-goal effort while preserving all earlier work as historical/unknown.

- Provider fallback from `fable` to `opus` when `fable` is unavailable (#274), so a transient model outage degrades gracefully instead of failing the prove call.

- Coordinated Codex proving: `./swarm/agent.sh --prove --provider codex` now uses Codex for proof attempts and decomposition while retaining the existing shared claims, local Lean verification, PR, and auto-merge lifecycle. Fork-only contributors continue to use the no-remote `--prove-local` path.

- Local provider smoke mode now auto-selects the highest-ranked open, unproved goal when `--goal` is omitted; an explicit goal remains available as an override.

- Gemini provider implementation guide (`docs/gemini-provider.md`): repository-specific adapter steps, deny-by-default policy template, effort/model handling, health and failure classification, hermetic tests, local acceptance smoke, and production-enablement criteria. The guide explicitly avoids `--yolo` and keeps Gemini local-only until its policy and failure behavior are demonstrated.

- Local proof-provider smoke mode: `./swarm/agent.sh --prove-local --goal <id> --provider claude|codex` runs proof generation and the full local kernel/audit verification from a preserved detached `HEAD` worktree without fetches, claims, pushes, PRs, GitHub calls, decomposition, affinity edits, or metrics. Codex uses non-interactive `codex exec` with a workspace sandbox and normalized Homebrew Node path; every provider call is followed by a git path guard that permits only the target Lean module. Local smoke defaults to one attempt and supports model/effort overrides.

- Third sourced target batch (ADR-012/Issue #257): 4 new harder open goals in the difficulty 3–4 band — `euclid-perfect-numbers` (Euclid-Euler perfect numbers), `sum-range-sq-mul-choose` (quadratic weighted sum of binomial coefficients), `sum-range-pentagonal-closed-form` (partial sums of pentagonal numbers), and `sq-add-sq-eq-three-mul-sq` (non-trivial integer solutions to $x^2 + y^2 = 3z^2$). Every statement type-checks against the pinned mathlib (rev c5ea00351c28) and is machine-absence-verified with provenance in `backlog/*.md`. This fulfills cgbarlow's request for harder targets to test the swarm's capabilities.

- Thread-B depth-2 dependency chain (ADR-010/ADR-014 routing demonstration): `sq-mod-three` (leaf), `prime-sq-mod-twenty-four` (mid, deps ⟨odd-sq-mod-eight, sq-mod-three⟩ — the classic 24 ∣ p²−1 for primes p > 3), `prime-sq-sub-sq-div-twenty-four` (root, deps ⟨prime-sq-mod-twenty-four⟩). First sourced goals with a depth-2 declared dependency tree; gap-based selection should route the leaves first and surface proved deps to the mid and root provers (phase3-run-002's open item)

- Second sourced target batch (ADR-012): 8 new prove goals in the classic-identities band, difficulty 2–3 — `sum-range-cube-odd`, `sum-range-pronic`, `sum-range-mul-two-pow`, `sum-range-recip-pronic`, `sum-range-pow-five-closed-form`, `three-cubes-div-nine`, `odd-sq-mod-eight`, `sum-range-sq-even`. Each statement type-checks against the pinned mathlib (rev c5ea00351c28) and is machine-absence-checked with flagged hits reviewed; provenance in `backlog/*.md`. Two candidates were dropped at the gate as already-in-mathlib (`Nat.fib_succ_eq_succ_sum`, Cassini's identity in `Mathlib/Data/Int/Fib/Lemmas.lean`) and three more at the probe stage (hockey stick `Nat.sum_Icc_choose`, weighted binomial row sum `sum_range_mul_choose`, Brahmagupta–Fibonacci in `Algebra/Ring/Identities`) — the ADR-012 Nicomachus discipline working as designed. The pool refills from empty to 8 open

### Changed

- Gate A now executes the authoritative axiom audit and full-library `leanchecker` replay in four bounded chunks, preserving complete verification while using the hosted runner's available cores. Superseded runs for the same PR or `main` ref are cancelled, and axiom reports are emitted as one valid JSON array.

- Status report (`docs/reports/status-2026-06-12.md`) updated in place through v1.6.2: the fifth mathlib-absent result (`not_prime_pow_four_add_four`, external machine binto-labs, #221) added to the results table; the first observed Gate A false negative it exposed recorded with its fix and canary guard (#231/#225/#233) plus a new honest-limits entry (the gate fails closed, not open); the ADR-021 sponsor draft-PR helper and the HEAD-stamped Nicomachus packet added to the upstream section; CONTRIBUTING/LICENSE noted; footer counts refreshed. README status line updated four → five

## [1.6.2] - 2026-06-12

### Added

- Gate A regression fixture `binder-shape-canary` (issue #231): a permanent, sound, mathlib-free goal carrying the implicit-then-named-hypothesis binder shape (`{n : Nat} (h : 1 < n)`) whose regenerated binding obligation is what tripped `linter.unusedVariables` under `--wfail`. Gate A rebuilds every proved goal's binding each run, so the canary keeps the #225 suppression verified **end-to-end** — a regression now goes red on the canary at the gate, not on a contributor's PR. Validated both ways (builds with the suppression; fails on `unused variable h` without). SPEC-011-A updated

### Added

- `CONTRIBUTING.md` (GitHub-recognised): the contributor guide — running an agent, proposing a target, the human-sponsored mathlib upstreaming process, and the development protocols/gates — moved out of the README, which now keeps a slim quickstart + pointer
- `LICENSE`: the Apache-2.0 license text the README and every upstream-packet copyright header ("described in the file LICENSE") already referenced but which was missing from the tree

### Fixed

- Statement-binding generator (ADR-011/SPEC-011-A): a goal whose statement has a named hypothesis binder following an implicit binder (e.g. `theorem t {n : ℕ} (hn : 1 < n) : …`) produced a binding obligation whose eta-expanded binder is flagged by `linter.unusedVariables`, failing the Gate A `--wfail` build for **any** correct proof of such a goal (first hit: `not-prime-pow-four-add-four`, PR #221). Generated bindings now carry `set_option linter.unusedVariables false in` — their force is the type-check, not lints, and the files are regenerated glue that never lands in a PR. Regression test added; all 38 current bindings rebuilt clean under `--wfail`

## [1.6.1] - 2026-06-12

### Added

- Sponsor PR helper (ADR-021, SPEC-021-A): `python3 -m tools.upstream.raise_pr --goal <id> --fork <you> --understood` opens a **draft** mathlib PR from a ready, HEAD-verified packet — clones master, applies the patch, pushes to your fork, and pre-fills the factual disclosure with a `SPONSOR: replace…` narrative placeholder. The policy boundary is enforced: refuses without `--understood` (your attestation that you've read the proof), refuses a non-`packet-ready`/unverified packet, opens a draft (never marks ready), writes no review reply. Closes the last-mile friction in [docs/upstreaming.md](docs/upstreaming.md) (the full sponsor process, linked from the README). 11 tests

## [1.6.0] - 2026-06-12

### Added

- Status report (`docs/reports/status-2026-06-12.md`, linked from the README): what unsorry has achieved against verified ground truth — four mathlib-absent results, both mechanisms demonstrated, three red-team rounds, the #190 review hardened, the upstream pipeline self-running — each claim stated with its honest limit
- Gate-A goal-immutability red team, round 003 (`docs/metrics/gate-a-redteam-003.md`): a live adversarial PR replaying issue #190's CRITICAL same-PR goal-tampering attack at full consistency was rejected by the ADR-018 step alone (gate-a red, gate-b green) — proving goal-statement immutability is the sole load-bearing layer, not redundant with Gate B

### Security

- CI supply-chain & workflow protection (ADR-019, SPEC-019-A — issue #190 HIGH/MEDIUM/LOW): every GitHub Action pinned to a commit SHA (`@<sha> # vX.Y.Z`) across all workflows; `.github/CODEOWNERS` over the trust-bearing paths (gates, audit, swarm, workflows); `docs/security-checklist.md` recording the repository-settings half (require-codeowner-review, force-push/tag protection) with the honest solo-maintainer trade-off and the "enable before opening to untrusted contributors" recommendation; and an `AuditFixtures/Opaque.lean` fixture pinning that `opaque` constants neither trip nor crash the axiom audit

### Security

- Goal statements are create-only (ADR-018, SPEC-018-A — issue #190's CRITICAL finding): every statement-integrity layer derives from `goals/<id>.lean` in the PR's own tree (binding regeneration, Gate B sha recomputation), so a PR consistently rewriting {goal `.lean`, record sha, index entry, proof} passed every gate. A new gate-a step (`tools/gate_a/check_goal_immutability.py`, 10 tests) diffs `goals/` against the PR base ref and rejects any modify/delete/rename/typechange of an existing `goals/*.lean` — existence-at-base is the one anchor a PR cannot rewrite. A wrong statement now gets a new goal id; the old is abandoned, never edited

## [1.5.1] - 2026-06-12

### Fixed

- `agent.sh` self-test on macOS: under bash 5.3 with a UTF-8 locale, the unbraced `$csv` adjacent to the `⟩` glyph in `set_goal_deps` parses the multibyte character into the identifier and aborts the suite at test 20/32 (`csv: unbound variable` under `set -u`), silently skipping the last 12 tests; the same line's `sed -i` also requires a backup-suffix argument under BSD sed. Braced the expansion and replaced in-place sed with portable write+rename. Repro: `bash -uc 'csv=x; echo "$csv⟩"'` on macOS/bash 5.3.9. A full-script scan (`perl -ne 'print if /\$[A-Za-z_]\w*[^\x00-\x7F]/'`) confirms this was the only expansion/glyph adjacency; the live loop path is unaffected

## [1.5.0] - 2026-06-12

### Added

- **Thread B exit — first compounding** (`docs/metrics/phase3-run-002.{json,md}`): `sum_range_cube_eq_triangular_sq` proved in 4m57s on the first attempt by **importing and invoking the swarm's own `nicomachus_sum_cubes`** (#154) — the first merged-lemma reuse by mechanism (ADR-014: proved deps surfaced in the prove prompt as importable `Unsorry.*` modules). Run-001's four recompositions corroborate (same surfacing, parents importing their proved subs). Honest limits recorded: depth-1 tree, one declared edge; deep bottom-up routing remains open. README compounding claim updated

## [1.4.0] - 2026-06-12

### Added

- **Thread A exit — the chain, in anger** (`docs/metrics/phase3-run-001.{json,md}`): `platonic_schlafli_pairs` (the Platonic-solids Schläfli arithmetic core, mathlib-absent) kernel-verified on main **via** a forced depth-3 decompose → prove-subs → recompose chain — 13 goals, 4 decompositions, 4 recompositions, statement binding held throughout, the parent's proof literally composing its sub-lemmas (#149→#211). Honest record: stage-1 budget forcing, three quota outages (the third absorbed unattended by ADR-016/017), the #166 conflicted-PR silent stall, claim races and their bounded cost, ladder rung stats (11/13 proofs at the cheapest rung). README/roadmap updated: "demonstrated on paper, not in anger" retired

### Fixed

- ADR-017 claim guard: GitHub title search tokenizes punctuation, so `"prove(<goal>):" in:title` also matched open PRs for sibling goals sharing the name's tokens — the leftover duplicate #198 (`...-s2-s2`) blocked both agents from claiming the recompose-ready parent. The verdict now comes from an exact title-prefix match over the search results; the regression (sibling↛parent, parent↛sub) is covered in `test_open_pr_claim_guard`

## [1.3.0] - 2026-06-11

### Added

- Swarm supervisor (ADR-017, SPEC-017-A): `swarm/supervise.sh` drives a goal tree to closure across infrastructure outages (exponential backoff on the ADR-016 exit-3 signal), cycle failures, and merge latency, terminating only when every goal in scope is `proved`. Each wait runs scope-limited PR hygiene: duplicate prove PRs (the claim-race symptom, #184/#185) are closed keeping the oldest, and CONFLICTING PRs are loudly flagged — GitHub runs no checks on a conflicted PR, so an armed auto-merge otherwise waits forever in silence (the #166 failure mode). Agent-side: prove selection now skips any goal whose prove PR is already open (the claim is released at PR-open, so the claims branch cannot see in-flight work). 3 supervisor self-tests + 1 agent self-test (32 total); agent-lint CI covers both scripts

### Added

- Infrastructure-failure guard (ADR-016, SPEC-016-A): a failed claude call that died in under `UNSORRY_FASTFAIL` seconds (default 240) and whose cheap-model health probe also fails is classified as an infrastructure failure — claim released with no `prove-failed` event, no decomposition, no demote, and the agent exits with code 3 for the orchestrator. Motivated by the two 2026-06-11 quota outages that each demoted a whole goal tree below τ_v. Prove prompt now also warns that Gate A's text lint greps comments for forbidden tokens (the word "axiom" in a doc comment failed an otherwise-sound proof)

### Changed

- Progressive effort escalation (ADR-015, SPEC-015-A, amends ADR-013): prove attempts now climb the effort ladder `high` → `xhigh` → `max` instead of running every attempt at static `max`, with the prove-mode attempt budget defaulting to 3 (one per rung) and decomposition always at the top rung. A set `UNSORRY_EFFORT` pins every attempt; fail-soft on CLIs without `--effort` unchanged. Each attempt's effort is logged for run reconstruction

### Added

- Cross-goal dependency reuse (ADR-014, SPEC-014-A): a goal's proved dependencies — declared `deps≜⟨…⟩` plus its own decomposition's subs — surface in the prove prompt as importable `Unsorry.*` modules with statements, so merged lemmas compound instead of being re-proved. Seeded the first dependency edge: `nicomachus-sum-cubes-triangular → nicomachus-sum-cubes` (thread B target)


### Fixed

- Index records no longer embed the statement (same brace hazard as the decomposition fix): `⟦Σ:Stmt⟧` → `⟦Σ:Source⟧{src≜goals/<goal>.lean}`, with Gate B recomputing the sha from the goal file when it exists (GB006 on mismatch; grandfathered translate-era entries keep the filename≡sha check). All 20 existing index records migrated; caught before the first brace-statement lemma (the recomposed platonic-schlafli-core parent) would have failed its prove PR


### Added

- Phase-3 roadmap (thread G): AISP value benchmark — observational instrumentation (tokens/record, Gate B first-try rejection rate) plus an A/B trial against a JSON mirror of the schemas and contract, to measure the notation's claimed value before contributors are asked to learn it


### Added

- PR labelling strategy (`docs/pr-labels.md`): 11 labels classified deterministically from the machine-generated titles (`tools/repo/pr_labels.py`, single source of truth), auto-applied by `.github/workflows/pr-labels.yml` on open/edit; all 145 historical PRs retroactively labelled. 5 classifier tests


### Added

- Phase-3 roadmap (thread E): failure-notes idea — a one-line approach diagnosis on the demote path, surfaced to the next claimant, so failed attempts become transferable knowledge instead of re-walked dead ends


### Fixed

- Decomposition records reference sub statements by content address (`sha≜`), never inline (SPEC-003-C): the record grammar reserves `{}` for block delimiters and real Lean statements contain braces — the first real decomposition (platonic-schlafli-core, Finset literal) broke the Σ-block parse and failed Gate B. Gate B now recomputes each sub's sha from `goals/<id>.lean` (GB016 on mismatch — strictly stronger integrity); `decompositions/` is created before first write (git tracks no empty dirs). 3 new regression tests


### Added

- Thread C plan: `docs/proposals/mathlib-upstream-plan.md` — the mathlib upstream path, designed around mathlib's verified AI-contribution policy (disclosure + `LLM-generated` label + author-understands-everything): machine-prepared upstream packets, human-sponsored PRs, Zulip-first; autonomous PRs are an explicit non-goal. Current candidates: the two mathlib-absent lemmas


### Added

- Model/effort policy for proof runs (ADR-013, SPEC-013-A): prove and decompose `claude` calls default to the most capable model (`fable`) at `--effort max`, env-overridable via `UNSORRY_MODEL`/`UNSORRY_EFFORT`, with the effort flag dropped fail-soft on CLIs that lack it; translation stays on `sonnet`. Run config recorded in the startup log. 28 self-tests


### Added

- Phase 3 roadmap proposal (`docs/proposals/phase3-roadmap.md`): the honest open frontier after Phase 2 — force decomposition end-to-end, drive to a chosen result through a dependency tree, upstream to mathlib, open the swarm at volume

### Changed

- README "The goal, honestly" reworked: the shakedown is over and Phase 2's bet paid off (first mathlib-absent lemma), reframed honestly — one elementary lemma is a proof of concept, not a research programme; the scale/compounding question is the Phase-3 frontier


### Added

- First sourced target batch (ADR-012): 10 vetted unformalised-in-mathlib theorems admitted to the backlog — sum of odd numbers = n², Faulhaber k=2/k=4 closed forms, Nicomachus triangular form, Fibonacci sum-of-squares, a factorial telescoping sum, n⁴+4 compositeness (Sophie Germain), the sum-of-odd-squares form, an alternating natural sum, and the Platonic-solids Schläfli arithmetic core. Each build-checked (type-checks vs mathlib v4.30.0) and machine-absence-checked; surfaced on the `docs/targets.md` board


### Added

- Backlog-sourcing pipeline (ADR-012, SPEC-012-A): `tools/sourcing/check_absence.py` (machine mathlib-absence check, grep-authoritative + best-effort Loogle, records the rev), `tools/sourcing/targets_board.py` → `docs/targets.md` (the human worklist), a `propose-target` issue template, and `docs/proposals/backlog-sourcing.md`. Scope boundary stated: formalisation gap, not open conjectures. 13 tests


## [1.2.0] - 2026-06-10

### Added

- **First unformalised-in-mathlib lemma proved**: Nicomachus's theorem `∑ k³ = (∑ k)²` (`nicomachus-sum-cubes`), verified mathlib-absent before the run, proved directly by the swarm with the statement-binding obligation satisfied — Phase 2's exit metric (#133)
- Phase-2 target run `phase2-run-001` (`docs/metrics/phase2-run-001.{md,json}`): direct-proof path, decomposition available but not needed, binding held (#134)

## [1.1.0] - 2026-06-10

### Added

- Phase-1 rerun baseline `phase1-run-002` (post-cache-fix): merge_rate 0.889 (↑ from 0.6), 0 prove failures, 0 gate-a failures, goal-level close rate 1.0
- Gate A binding red-team round 002 (`docs/metrics/gate-a-redteam-002.md`): 3/3 vacuity attacks blocked by the statement-binding gate, honest control passes

### Added

- Phase-2 Stage D — statement-binding gate (ADR-011, SPEC-011-A): Gate A now regenerates, for every proved goal, a kernel obligation `theorem <name>_binding_check : <∀-goal-type> := <name>` and builds it under `--wfail`, so a proof of a weakened or vacuous statement under the goal's name (the #64 class) fails to inhabit the goal type and goes red. Non-bypassable (Gate A controls generation, not the contributor); covers decomposition sub-lemmas. `tools/lean_sig.py` extracted (shared Lean-signature parsing); 6 new tests


### Added

- Phase-2 Stage C — goal decomposition (ADR-009, SPEC-009-A): on prove-budget exhaustion the agent drives `claude` to split the parent into 2-8 sub-lemma goals (typed `Post⊆Pre` edges, depth ≤3), requeues them as `open` prove goals, and parks the parent `blocked`; an unblock sweep re-opens a parent once all its subs are proved. Soundness unchanged — the parent still closes only through Gate A. Gate B gains acyclicity + strictly-smaller guardrails; 3 new agent self-tests + 3 Gate B tests. ADR-009 Accepted


### Added

- Phase-2 Stage B — affinity-weighted, gap-based goal selection (ADR-010, SPEC-010-A): selection now ranks claimable goals by (affinity desc, gap asc, id asc), skipping below-τ_v patterns; +1 affinity on a merge (folded into the prove PR), -10 on a failed attempt (a gated demote PR); affinity is an advisory `aff` field on goal records that degrades to 0 on absence/garbage. 5 new agent self-tests (24 total). ADR-010 Accepted
- Phase-2 plan (proposed): [`docs/proposals/phase2-plan.md`](docs/proposals/phase2-plan.md), candidate-target shortlist [`docs/phase2-targets.md`](docs/phase2-targets.md), and three ADRs — ADR-009 (goal decomposition on prove-budget exhaustion), ADR-010 (affinity-weighted gap-based selection), ADR-011 (statement-binding gate, closing the meaningfulness gap the W3 red team exposed)
- README: "Why this matters" and "The goal, honestly" — the purpose, value, and honest limits of the work, with Phase-2 links


## [1.0.0] - 2026-06-10

### Added

- Contributor-readiness checklist evidence (`docs/metrics/checklist-evidence.md`): all six items (a)–(f) adversarially verified `sufficient` at high confidence; the public contributor invitation opens (#79)
- README quickstart verified to run clean from a fresh clone (checklist item (f))


## [0.6.0] - 2026-06-10

### Added

- Phase-1 swarm run 001 (W4): 3 prover agents drove `claude` to write real Lean proofs; 3 theorems proved and merged into the verified library by a non-author agent (`prover-alpha`) end-to-end; metrics at `docs/metrics/phase1-run-001.{md,json}` (#75)
- First merged proofs: `int_add_neg_thm`, `int_neg_neg_thm`, `and_comm_imp_thm` in `library/Unsorry/`

### Fixed

- Prove cycle recompiled mathlib from source: the PR worktree has no `.lake`, so verification rebuilt all of mathlib and blew the attempt budget (phase1-run-001). `run_proof` now restores the prebuilt cache (`lake exe cache get`, best-effort) in the worktree before the first build (SPEC-007-A)

### Added

- Phase-1 backlog: 20 known-true prove-phase goals (`goals/*.aisp` + statement `.lean` files carrying `sorry`) spanning Nat/Int algebra, order, divisibility, gcd, parity, list and propositional facts; minimal imports, all type-check, all audit clean under `--allow-sorry`

## [0.5.0] - 2026-06-10

### Added

- Gate A red-team round 001 (W3): 9 adversarial bypass vectors as real PRs (#56–#64); 9/9 blocked after the autoImplicit fix. Evidence at `docs/metrics/gate-a-redteam-001.md` — checklist item (a)

### Fixed

- Gate A autoImplicit bypass found by the W3 red team (PR #64): a `set_option autoImplicit true` split across lines defeated the per-line diff lint and let a vacuous (sound-but-meaningless) theorem into `library/`. New authoritative whole-file, whitespace-collapsed check `tools/gate_a/check_library_options.py` (12 tests) — `autoImplicit`/`relaxedAutoImplicit` re-enables in the verified library now fail Gate A regardless of source formatting (SPEC-006-B)

## [0.4.0] - 2026-06-10

### Added

- Lean 4 project: `lean-toolchain` pinned to `leanprover/lean4:v4.30.0`, `lakefile.toml` with two packages — `UnsorryLibrary` (verified, zero-sorry) and `UnsorryGoals` (sorries expected) — mathlib required at release tag `v4.30.0`, manifest committed (ADR-002, ADR-006)
- First verified lemma `nat_zero_lt_succ` with content-addressed index entry `library/index/4c71a8b4….aisp` (goal `nat-zero-lt-succ`)
- ADR-006 Gate A Soundness Enforcement; SPEC-006-A (axiom audit executable), SPEC-006-B (gate-a workflow)
- `lake exe axiom_audit` — per-declaration transitive axiom audit (whitelist `propext`/`Classical.choice`/`Quot.sound`, `--allow-sorry` for goals); `AuditFixtures` adversarial lib + 16-assertion acceptance script `tools/gate_a/test_audit.sh`
- **Gate A live**: `gate-a.yml` (always-report detect job; lean-action mathlib cache; `--wfail` library build; axiom audit; leanchecker kernel replay; audit self-test; textual lint belt; axiom-footprint artifact + sticky PR comment) — required status check on `main` alongside `gate-b` (ADR-005, ADR-006, SPEC-006-B)

## [0.3.0] - 2026-06-10

### Added

- Phase-0 swarm trial run 001: four agent identities on two models, 39 claim cycles, 38 autonomous PR merges, TTL reap observed; metrics + evidence at `docs/metrics/phase0-run-001.{md,json}` (#47)
- `docs/metrics/METRICS.md` — metric definitions and run index

### Fixed

- Translation convergence race under overlapping PRs — convergence sweep, SPEC-007-A step 1b (#8)
- Fidelity normalizer false positives on redundant parentheses — normalization step 5; both trial flags adjudicated equivalent and resolved (#50)

### Changed

- All 10 Phase-0 backlog goals now `translated`; all 3 planted paraphrase pairs converged to byte-equal content addresses
- README roadmap: Phase 0 ticked with metrics link

## [0.2.0] - 2026-06-10

### Added

- `tools/gate_b/` — in-repo Gate B validator (GB001–GB018), CI workflow `gate-b.yml` (required job + advisory upstream aisp-validator job)
- `tools/gate_b/reaper.py` + `reaper.yml` — expired-claim reaper on a 15-min cron against the orphan `claims` branch
- `tools/fidelity/` — statement normalizer (NFC, canonical symbols, α-rename) + differ; content-address shas
- `swarm/agent.sh` — Phase-0 translation-only agent loop (ADR-007, SPEC-007-A)
- `swarm/prompts/translate.md` — one-shot translation prompt with pinned symbol palette
- `backlog/` seeded with 10 known-true statements (3 planted paraphrase pairs + 4 singletons) and matching `goals/` records
- ADR-007 Agent Identity and Budgets; SPEC-007-A Agent Loop Script
- Orphan `claims` branch created (ADR-004)

- `swarm/protocol.aisp` — the swarm contract (validates ◊⁺⁺ Platinum with aisp-validator 0.3.0); SPEC-003-D
- `swarm/AI_GUIDE.md` — AISP 5.1 grammar vendored from bar181/aisp-open-core (MIT, attribution: Bradley Ross)
- Record schemas: goal (SPEC-003-A), claim (SPEC-003-B), translation + decomposition + normalization/content-addressing (SPEC-003-C), claim lifecycle + reaper (SPEC-004-A)
- `claims/README.md` — pointer to the claims-branch mechanism (ADR-004)
- Gate B fixture corpus under `tools/gate_b/tests/fixtures/` (valid trees + 12 violation trees, TDD seed for the validator)

## [0.1.0] - 2026-06-10

### Added

- Vendored development protocols at `docs/protocols.md` (from [cgbarlow/protocols](https://github.com/cgbarlow/protocols)), adopted as binding (ADR-001)
- ADR-001 — Adopt Development Protocols
- ADR-002 — Lean 4 + mathlib4 Pinned to Release Tags
- ADR-003 — AISP Coordination Format with In-Repo Validation
- ADR-004 — Claims on a Dedicated Branch, First-Push-Wins
- ADR-005 — Autonomous Merge Policy
- `CLAUDE.md` development guide
- This changelog
