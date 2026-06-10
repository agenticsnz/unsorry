# Phase-2 target run — run 001 (first Phase-2 target: Nicomachus Σk³=(Σk)²)

**run_id:** `phase2-run-001` · **date:** 2026-06-10 (UTC) · **trial:** First Phase-2 target run (Stage E) — one prover agent against the first seeded, mathlib-absent target.

Machine record: [`phase2-run-001.json`](phase2-run-001.json).

## Exit-metric verdict (read this first)

**The exit metric is: was a first lemma proved that was NOT already in mathlib?**

**MET.** `nicomachus-sum-cubes` — Nicomachus's theorem, ∑_{k<n} k³ = (∑_{k<n} k)² — is kernel-verified on `main` with `gate-a` green and the statement-binding obligation satisfied. It is the first non-trivial lemma the swarm has proved that did not already exist in mathlib.

| Dimension | Value |
|---|---|
| `target_reached` | **true** |
| `proof_path` | **direct** (proved in one cycle, no decomposition) |
| `decomposition_exercised` | **false** |
| `subs_total` / `subs_proved` | **0 / 0** |
| `binding_held` | **true** (gate-a statement-binding step success on merge commit `79c6f2c`) |
| target proof PR | **#133** (MERGED), merge commit `79c6f2c` |
| open nicomachus PRs remaining | **0** |

## The target, and why it counts

The seeded Phase-2 target (PR #131) is:

```
theorem nicomachus_sum_cubes (n : ℕ) :
    (∑ k ∈ Finset.range n, k ^ 3) = (∑ k ∈ Finset.range n, k) ^ 2
```

Nicomachus's theorem: the sum of the first n cubes equals the square of the sum of the first n naturals. `backlog/nicomachus-sum-cubes.md` records that this was **verified mathlib-absent against the pinned mathlib v4.30.0** before the run — only the general Bernoulli power-sum `sum_range_pow` exists, which is a different statement. So proving it is a genuine new lemma, not a re-derivation of an existing mathlib result. This is the property that makes it a meaningful Phase-2 exit metric rather than a Phase-1 warm-up.

Run scope was set via the `--goal nicomachus-sum-cubes` enabler (PR #132), which scopes selection to a target and its decomposition descendants. The exit condition was simply: the target proved on main.

## What the swarm did

One prover agent, **`e-alpha`** (driving `claude`), ran the real swarm prove workflow for a **single cycle** and proved the target **directly**. The chronology, from its telemetry and corroborated by `gh` ground truth:

1. **Claimed** the goal on the second attempt — the first claim push lost the release-branch race and was re-pushed after a rebase. This is the same optimistic-concurrency pattern seen in `phase1-run-002`, **not** a collision (no `collision` event).
2. **`claude prove` attempt 1 failed / timed out.** This consumed most of the ~30-minute cycle wall.
3. **Attempt 2 succeeded** — "proof of nicomachus-sum-cubes verified locally — statement bound (attempt 2)". The statement-binding gate (ADR-011) confirmed the proof matched the exact target type.
4. **Opened PR #133.** Auto-merge (squash) was enabled by `cgbarlow`; it merged automatically at `2026-06-10T20:33:41Z` once CI passed (merge commit `79c6f2c`).
5. The settle loop reported **0 open nicomachus PRs** and exited cleanly (did not hit timeout).

The agent stopped after one cycle because the exit condition (target proved on main) was met.

## Proof path: direct (best case, path (a))

The target was proved **directly, in one cycle, with no decomposition**.

- No `decompositions/` directory exists at this HEAD.
- No `goals/nicomachus-sum-cubes-s*.aisp` sub-goal files exist.
- No `decomposed` telemetry event was emitted.
- `goals/nicomachus-sum-cubes.aisp` shows `deps≡⟨⟩` (no dependencies) and `status≡proved`, `difficulty≡3`.

This is the best-case outcome: a non-trivial, mathlib-absent target cleared in a single direct proof.

## Decomposition tree

**None — decomposition was not exercised this run.** `subs_total = 0`, `subs_proved = 0`.

The Stage-C decomposition machinery (ADR-009) was **available** but **never triggered**, because the direct proof landed first and met the exit condition. There is therefore no decomposition tree to report, and — recorded honestly as a coverage gap — the end-to-end **decompose → prove subs → recompose** path remains **untested against a real target** after this run. That path's first real exercise will have to come from a target that the direct proof cannot close in the attempt budget; Nicomachus was not that target.

## Binding obligation — the load-bearing gate

This is the first Phase-2 target to clear the **ADR-011 statement-binding gate** in anger, and `binding_held = true`.

On the merge commit `79c6f2c`, gate-a job **80657275950** succeeded on every load-bearing step:

| Step | Conclusion |
|---|---|
| Build (lean-action, mathlib binary cache) | success |
| **Generate statement-binding obligations** | **success** |
| Library build — zero-warning bar (`--wfail`) | success |
| Axiom audit (authoritative) | success |
| Kernel replay (leanchecker) | success |
| Audit self-test (gate cannot rot silently) | success |
| Forbidden elaboration options in library | success |

The "Generate statement-binding obligations" success is what makes the result trustworthy: it proves the merged Lean theorem has the **exact** seeded type, not a weaker paraphrase. Confirmed independently by reading the index `.aisp` statement and the library-module signature — both match the seed verbatim:

- Index: `library/index/1be96a4d1204…aisp` → `⟦Σ:Stmt⟧{stmt≜theorem nicomachus_sum_cubes (n : ℕ) : (∑ k ∈ Finset.range n, k ^ 3) = (∑ k ∈ Finset.range n, k) ^ 2}`.
- Module: `library/Unsorry/NicomachusSumCubes.lean`, same signature.

All other required checks on PR #133 are green: `gate-b` pass, `agent-lint` pass, `aisp-advisory` pass, `detect` pass.

## Soundness spot-check

`library/Unsorry/NicomachusSumCubes.lean` is a genuine, non-vacuous ~24-line proof:

- Induction on `n`; zero case `simp`.
- Succ case rewrites `Finset.sum_range_succ` twice plus the IH, then case-splits on `n`.
- The succ-succ case sets `S := ∑ k ∈ Finset.range (m+1), k`, derives the triangular closed form `S * 2 = (m+1) * m` from `Finset.sum_range_id_mul_two`, then a `calc` block expands `(S + (m+1))^2 = S^2 + (m+1)^3` and closes with `linarith`.

Forbidden-tactic scan on the library module is **CLEAN**: no `sorry`, `admit`, `native_decide`, or `axiom` (grep returns no matches). Note that `goals/nicomachus-sum-cubes.lean` still holds the original seed **stub** ending in `sorry` — that is the unproved goal statement by design; the real proof lives in the library module. Don't be misled by the stub.

## The attempt-1 timeout — honest accounting

The cycle was not frictionless: `claude prove` **attempt 1 failed/timed out**, eating most of the ~30-minute wall before **attempt 2** produced the merged proof. This is the prover's note verbatim:

> claude prove attempt 1 failed/timed out; attempt 2 succeeded — "proof of nicomachus-sum-cubes verified locally — statement bound (attempt 2)".

This is **not** a soundness failure and **not** a `prove-failed` outcome at the run level — it is a single retry inside the attempt budget, and the merged artifact is attempt 2, which the statement-binding gate accepted. There was no `lake`/kernel error on the merged path: gate-a's Lean build, axiom audit, and kernel replay all passed. The only "sticking point" worth recording is the attempt-1 timeout cost, which is the same class of slow-`claude`/slow-verify wall-budget pressure characterised in earlier runs, not a mathematical or binding failure.

## What this run establishes

- **First mathlib-absent lemma proved.** The swarm closed a real, non-trivial target (`nicomachus-sum-cubes`) that does not exist in mathlib, kernel-verified on main, binding obligation held. The exit metric for Phase-2's first target run is **met**.
- **Direct path works on a difficulty-3 target.** No decomposition was needed; one agent, one cycle (modulo one retry).
- **The binding gate fired for real and passed.** ADR-011 statement-binding is no longer only red-team-validated (gate-a-redteam-002) — it has now gated a genuine new-lemma merge and confirmed exact-type fidelity.
- **Coverage gap, stated plainly:** decomposition (Stage C) was available but **not exercised**. The recompose path still awaits a target the direct proof cannot close.
