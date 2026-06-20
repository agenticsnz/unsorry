# Upstream packet: `sum-range-k-mul-choose-mul-four-pow-closed`

Status: packet-ready · generated mechanically (ADR-020 / SPEC-020-A) · sponsor: Chris Barlow

## The statement (as proved here)

```lean
import Mathlib

theorem sum_range_k_mul_choose_mul_four_pow_closed (n : ℕ) : 5 * ∑ k ∈ Finset.range (n + 1), k * n.choose k * 4 ^ k = 4 * n * 5 ^ n := by
  sorry
```

Kernel-verified on `main`: `library/Unsorry/SumRangeKMulChooseMulFourPowClosed.lean` (theorem `sum_range_k_mul_choose_mul_four_pow_closed`),
through Gate A (build `--wfail`, axiom audit against the standard whitelist, leanchecker
kernel replay, regenerated ADR-011 binding obligation).

## Proposed contribution

The `git apply`-able new-file diff is at [`sum-range-k-mul-choose-mul-four-pow-closed.patch`](sum-range-k-mul-choose-mul-four-pow-closed.patch). The target path
`Mathlib/Unsorry/SumRangeKMulChooseMulFourPowClosed.lean` is a **placeholder** — file placement and the
final name are Zulip questions, not ours to decide. Content:

```lean
/-
Copyright (c) 2026 Chris Barlow. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Chris Barlow
-/
import Mathlib

theorem sum_range_k_mul_choose_mul_four_pow_closed (n : ℕ) : 5 * ∑ k ∈ Finset.range (n + 1), k * n.choose k * 4 ^ k = 4 * n * 5 ^ n := by
  have hbin : ∀ m : ℕ, ∑ j ∈ Finset.range (m + 1), m.choose j * 4 ^ j = 5 ^ m := by
    intro m
    have h := add_pow (4 : ℕ) 1 m
    simp only [one_pow, mul_one, Nat.cast_id] at h
    rw [show (4 : ℕ) + 1 = 5 from rfl] at h
    rw [h]
    apply Finset.sum_congr rfl
    intro j hj
    ring
  cases n with
  | zero => simp
  | succ m =>
    rw [Finset.sum_range_succ']
    simp only [Nat.zero_mul, pow_zero, mul_one, add_zero]
    have key : ∀ j ∈ Finset.range (m + 1),
        (j + 1) * (m + 1).choose (j + 1) * 4 ^ (j + 1)
          = (m + 1) * (4 * (m.choose j * 4 ^ j)) := by
      intro j hj
      have h := Nat.add_one_mul_choose_eq m j
      rw [pow_succ]
      have h2 : (j + 1) * (m + 1).choose (j + 1) = (m + 1) * m.choose j := by
        rw [h, Nat.mul_comm]
      calc (j + 1) * (m + 1).choose (j + 1) * (4 ^ j * 4)
          = ((j + 1) * (m + 1).choose (j + 1)) * (4 ^ j * 4) := by ring
        _ = ((m + 1) * m.choose j) * (4 ^ j * 4) := by rw [h2]
        _ = (m + 1) * (4 * (m.choose j * 4 ^ j)) := by ring
    rw [Finset.sum_congr rfl key]
    rw [← Finset.mul_sum, ← Finset.mul_sum, hbin m]
    ring
```

## Dedup at mathlib HEAD

- mathlib revision scanned: `2dfe37a6fa59521018b61dc988495a84dd47dd30`
- patterns: `\bsum_range_k_mul_choose_mul_four_pow_closed\b`
- verdict: **no-local-match**
- matches:
- none

A name-grep is a pre-filter, not a proof of absence; the kernel build at HEAD
(`tools/upstream/verify_head.sh`) is the strong evidence and its result belongs in the
PR conversation.

## Provenance dossier

| Field | Value |
|---|---|
| source | #400 Identity Engine (ADR-043) — binomial family; promoted from candidate backlog (#610). |
| reference | Five times the sum of k times n-choose-k times four-to-the-k equals four-n times five-to-the-n. Not a named mathlib lemma in this form. |
| absence | no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add). |
| triviality | machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15). |
| difficulty | 3 |
| decomposition sketch | Same k*C(n,k)=n*C(n-1,k-1) reindex with binomial theorem (1+4)^(n-1), or induction with Finset.sum_range_succ. Verified to build (lake env lean). |
| title | Five times the sum of k times n-choose-k times four-to-the-k equals four-n times five-to-the-n. |

Proof produced by an autonomous Claude agent swarm (model policy ADR-013/ADR-015:
`fable`, progressive effort), merged with no human review through two CI gates
(ADR-006 soundness, Gate B hygiene). Full machine history: the goal's PR trail in
this repository.

## AI disclosure (paste-ready facts)

> The Lean proof in this PR was produced by an autonomous LLM agent
> (Anthropic Claude, model `fable`) operating in the `unsorry` proof swarm
> (github.com/agenticsnz/unsorry), and was machine-verified there by kernel
> replay, an axiom audit against the standard whitelist (`propext`,
> `Classical.choice`, `Quot.sound`), and a CI-regenerated statement-binding
> obligation. I have read and understood the proof in full and can justify
> each step without AI assistance. Label: `LLM-generated`.

## For the sponsor

1. Read the proof until you can justify every step **without AI assistance** —
   mathlib reviewers will expect exactly that.
2. **Zulip first**, in your own words: is the lemma wanted, where does it live,
   what should it be called? The PR-description narrative and every review reply
   likewise **must be rewritten in your own words** — mathlib policy forbids
   LLM-written conversation; only the lemma itself (disclosed) and the factual
   disclosure block above may be pasted.
3. **Raise the draft PR with one command** once you've done 1–2 — from the
   unsorry repo root:
   ```
   python3 -m tools.upstream.raise_pr --goal sum-range-k-mul-choose-mul-four-pow-closed --fork <your-github-user> --understood
   ```
   It clones mathlib master, applies the patch to a fresh branch, pushes to
   your fork, and opens a **draft** PR pre-filled with the factual disclosure
   and a placeholder where your narrative goes. (`--understood` is your
   attestation that you've read the proof; `--dry-run` shows the plan first.)
   The machine never marks it ready and never writes a review reply.
4. Write your narrative in the draft, apply the `LLM-generated` label, then
   **you** flip draft → ready. Expect the linter to want golfing (binder
   names, line length) — that editing is yours. See [docs/upstreaming.md](../upstreaming.md).
5. Record the outcome on the targets board (`in-discussion → pr-open →
   merged | declined`). **Declined is a valid, recorded result.**
