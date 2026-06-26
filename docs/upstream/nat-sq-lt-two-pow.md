# Upstream packet: `nat-sq-lt-two-pow`

Status: packet-ready · generated mechanically (ADR-020 / SPEC-020-A) · sponsor: Chris Barlow

## The statement (as proved here)

```lean
import Mathlib

theorem sq_lt_two_pow_of_five_le {n : ℕ} (hn : 5 ≤ n) : n ^ 2 < 2 ^ n := by
  sorry
```

Kernel-verified on `main`: `library/Unsorry/NatSqLtTwoPow.lean` (theorem `sq_lt_two_pow_of_five_le`),
through Gate A (build `--wfail`, axiom audit against the standard whitelist, leanchecker
kernel replay, regenerated ADR-011 binding obligation).

## Proposed contribution

The `git apply`-able new-file diff is at [`nat-sq-lt-two-pow.patch`](nat-sq-lt-two-pow.patch). The target path
`Mathlib/Unsorry/NatSqLtTwoPow.lean` is a **placeholder** — file placement and the
final name are Zulip questions, not ours to decide. Content:

```lean
/-
Copyright (c) 2026 Chris Barlow. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Chris Barlow
-/
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Ring

theorem sq_lt_two_pow_of_five_le {n : ℕ} (hn : 5 ≤ n) : n ^ 2 < 2 ^ n := by
  obtain ⟨k, rfl⟩ := Nat.exists_eq_add_of_le hn
  suffices h : ∀ k : ℕ, (5 + k) ^ 2 < 2 ^ (5 + k) by exact h k
  intro k
  induction k with
  | zero => norm_num
  | succ k ih =>
      simpa [Nat.add_assoc] using sq_lt_two_pow_step_from_five (n := 5 + k) (by omega) ih
```

## Dedup at mathlib HEAD

- mathlib revision scanned: `2216b5b1ea909cc6bcd2c3b45516c1ece827135f`
- patterns: `\bsq_lt_two_pow_of_five_le\b`
- verdict: **no-local-match**
- matches:
- none

A name-grep is a pre-filter, not a proof of absence; the kernel build at HEAD
(`tools/upstream/verify_head.sh`) is the strong evidence and its result belongs in the
PR conversation.

## Provenance dossier

| Field | Value |
|---|---|
| source | Classic crossover inequality (standard induction exercise) |
| reference | n² < 2ⁿ for n ≥ 5. mathlib has linear `Nat.lt_two_pow`-style bounds and Bernoulli (`one_add_mul_le_pow`) but no quadratic-vs-exponential crossover lemma. |
| absence | no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035) |
| triviality | machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14) |
| difficulty | 3 |
| decomposition sketch | Two-layer induction (not one-shot-closable). L1 helper 2n+1 < n² for n≥3 (small induction / omega after bounding). L2 base n=5 (25<32) by decide/norm_num. L3 induction step: `pow_succ` gives 2^(n+1)=2·2^n, IH n²<2^n. L4 (n+1)² ≤ 2n² via L1, chain to < 2·2^n. |
| title | For every natural n ≥ 5, n² < 2ⁿ — the quadratic-vs-exponential crossover. |

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
   python3 -m tools.upstream.raise_pr --goal nat-sq-lt-two-pow --fork <your-github-user> --understood
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
