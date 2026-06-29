# Upstream packet: `putnam-1962-a5`

Status: packet-ready · generated mechanically (ADR-020 / SPEC-020-A) · sponsor: Chris Barlow

## The statement (as proved here)

```lean
import Mathlib

abbrev putnam_1962_a5_solution : ℕ → ℕ := fun n : ℕ => n * (n + 1) * 2^(n - 2)

theorem putnam_1962_a5 : ∀ n ≥ 2, putnam_1962_a5_solution n = ∑ k ∈ Finset.Icc 1 n, Nat.choose n k * k^2 := by
  sorry
```

Kernel-verified on `main`: `library/Unsorry/Putnam1962A5.lean` (theorem `putnam_1962_a5`),
through Gate A (build `--wfail`, axiom audit against the standard whitelist, leanchecker
kernel replay, regenerated ADR-011 binding obligation).

## Proposed contribution

The `git apply`-able new-file diff is at [`putnam-1962-a5.patch`](putnam-1962-a5.patch). The target path
`Mathlib/Unsorry/Putnam1962A5.lean` is a **placeholder** — file placement and the
final name are Zulip questions, not ours to decide. Content:

```lean
/-
Copyright (c) 2026 Chris Barlow. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Chris Barlow
-/
import Mathlib

theorem putnam_1962_a5 : ∀ n ≥ 2, putnam_1962_a5_solution n = ∑ k ∈ Finset.Icc 1 n, Nat.choose n k * k^2 := by
  intro n hn
  show n * (n + 1) * 2 ^ (n - 2) = ∑ k ∈ Finset.Icc 1 n, Nat.choose n k * k ^ 2
  rw [putnam_1962_a5_sum_eq n]
  have hpow : (2 : ℕ) ^ n = 2 ^ (n - 2) * 4 := by
    conv_lhs => rw [show n = (n - 2) + 2 from by omega]
    rw [pow_add]
    norm_num
  have hcancel : 4 * (∑ i ∈ Finset.range (n + 1), i ^ 2 * n.choose i)
      = 4 * (n * (n + 1) * 2 ^ (n - 2)) := by
    rw [Putnam1962A5Aux.core n, hpow]
    ring
  exact (Nat.eq_of_mul_eq_mul_left (by norm_num) hcancel).symm
```

## Dedup at mathlib HEAD

- mathlib revision scanned: `571b8a8e54219b4d393f75f4b8653fac08197fcc`
- patterns: `\bputnam_1962_a5\b`
- verdict: **no-local-match**
- matches:
- none

A name-grep is a pre-filter, not a proof of absence; the kernel build at HEAD
(`tools/upstream/verify_head.sh`) is the strong evidence and its result belongs in the
PR conversation.

## Provenance dossier

| Field | Value |
|---|---|
| source | putnam-v1 benchmark suite |
| reference | github.com/trishullab/PutnamBench |
| absence | imported benchmark statement (absent from the library) |
| triviality | classified credited/glue at registration (ADR-078 full battery) |
| difficulty | 4 |
| decomposition sketch | flat benchmark obligation under the suite root |
| title | putnam-v1 benchmark obligation putnam_1962_a5 |

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
   python3 -m tools.upstream.raise_pr --goal putnam-1962-a5 --fork <your-github-user> --understood
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
