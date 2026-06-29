# Upstream packet: `three-fourth-powers-zmod-sixteen-mem`

Status: packet-ready · generated mechanically (ADR-020 / SPEC-020-A) · sponsor: Chris Barlow

## The statement (as proved here)

```lean
import Mathlib

set_option maxRecDepth 8000 in
theorem three_fourth_powers_zmod_sixteen_mem (a b c : ℤ) :
    ((a^4 + b^4 + c^4 : ℤ) : ZMod 16) ∈ ({0, 1, 2, 3} : Set (ZMod 16)) := by
  sorry
```

Kernel-verified on `main`: `library/Unsorry/ThreeFourthPowersZmodSixteenMem.lean` (theorem `three_fourth_powers_zmod_sixteen_mem`),
through Gate A (build `--wfail`, axiom audit against the standard whitelist, leanchecker
kernel replay, regenerated ADR-011 binding obligation).

## Proposed contribution

The `git apply`-able new-file diff is at [`three-fourth-powers-zmod-sixteen-mem.patch`](three-fourth-powers-zmod-sixteen-mem.patch). The target path
`Mathlib/Unsorry/ThreeFourthPowersZmodSixteenMem.lean` is a **placeholder** — file placement and the
final name are Zulip questions, not ours to decide. Content:

```lean
/-
Copyright (c) 2026 Chris Barlow. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Chris Barlow
-/
import Mathlib

theorem three_fourth_powers_zmod_sixteen_mem (a b c : ℤ) :
    ((a^4 + b^4 + c^4 : ℤ) : ZMod 16) ∈ ({0, 1, 2, 3} : Set (ZMod 16)) := by
  first
    | (push_cast; generalize (a : ZMod 16) = z0; generalize (b : ZMod 16) = z1; generalize (c : ZMod 16) = z2; revert z0 z1 z2; decide)
    | (generalize (a : ZMod 16) = z0; generalize (b : ZMod 16) = z1; generalize (c : ZMod 16) = z2; revert z0 z1 z2; decide)
    | (push_cast; decide)
    | decide
```

## Dedup at mathlib HEAD

- mathlib revision scanned: `571b8a8e54219b4d393f75f4b8653fac08197fcc`
- patterns: `\bthree_fourth_powers_zmod_sixteen_mem\b`
- verdict: **no-local-match**
- matches:
- none

A name-grep is a pre-filter, not a proof of absence; the kernel build at HEAD
(`tools/upstream/verify_head.sh`) is the strong evidence and its result belongs in the
PR conversation.

## Provenance dossier

| Field | Value |
|---|---|
| source | #400 Identity Engine (ADR-043) — power-residue family; promoted from candidate backlog. |
| reference | A sum of three integer fourth powers is always congruent to 0, 1, 2, or 3 modulo 16. Not a named mathlib lemma in this form. |
| absence | no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd). |
| triviality | machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15). |
| difficulty | 3 |
| decomposition sketch | decide over the finite ZMod 16 cubed domain (each fourth power is 0 or 1 mod 16). Verified to build (lake env lean) at sourcing. |
| title | A sum of three integer fourth powers is always congruent to 0, 1, 2, or 3 modulo 16. |

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
   python3 -m tools.upstream.raise_pr --goal three-fourth-powers-zmod-sixteen-mem --fork <your-github-user> --understood
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
