# Upstream packet: `sum-three-squares-zmod-eight-ne-seven`

Status: packet-ready · generated mechanically (ADR-020 / SPEC-020-A) · sponsor: Chris Barlow

## The statement (as proved here)

```lean
import Mathlib

theorem sum_three_squares_zmod_eight_ne_seven (a b c : ℤ) : (((a ^ 2 + b ^ 2 + c ^ 2 : ℤ)) : ZMod 8) ≠ 7 := by
  sorry
```

Kernel-verified on `main`: `library/Unsorry/SumThreeSquaresZmodEightNeSeven.lean` (theorem `sum_three_squares_zmod_eight_ne_seven`),
through Gate A (build `--wfail`, axiom audit against the standard whitelist, leanchecker
kernel replay, regenerated ADR-011 binding obligation).

## Proposed contribution

The `git apply`-able new-file diff is at [`sum-three-squares-zmod-eight-ne-seven.patch`](sum-three-squares-zmod-eight-ne-seven.patch). The target path
`Mathlib/Unsorry/SumThreeSquaresZmodEightNeSeven.lean` is a **placeholder** — file placement and the
final name are Zulip questions, not ours to decide. Content:

```lean
/-
Copyright (c) 2026 Chris Barlow. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Chris Barlow
-/
import Mathlib

theorem sum_three_squares_zmod_eight_ne_seven (a b c : ℤ) : (((a ^ 2 + b ^ 2 + c ^ 2 : ℤ)) : ZMod 8) ≠ 7 := by
  first
    | (push_cast; generalize (a : ZMod 8) = z0; generalize (b : ZMod 8) = z1; generalize (c : ZMod 8) = z2; revert z0 z1 z2; decide)
    | (generalize (a : ZMod 8) = z0; generalize (b : ZMod 8) = z1; generalize (c : ZMod 8) = z2; revert z0 z1 z2; decide)
    | (push_cast; decide)
    | decide
```

## Dedup at mathlib HEAD

- mathlib revision scanned: `571b8a8e54219b4d393f75f4b8653fac08197fcc`
- patterns: `\bsum_three_squares_zmod_eight_ne_seven\b`
- verdict: **no-local-match**
- matches:
- none

A name-grep is a pre-filter, not a proof of absence; the kernel build at HEAD
(`tools/upstream/verify_head.sh`) is the strong evidence and its result belongs in the
PR conversation.

## Provenance dossier

| Field | Value |
|---|---|
| source | #400 Identity Engine (ADR-043) — modular-arith family. |
| reference | A sum of three integer squares is never congruent to 7 modulo 8 (a case of the three-square theorem). Not a named mathlib lemma in this form. |
| absence | no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035). |
| triviality | machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14). |
| difficulty | 3 |
| decomposition sketch | Cast to ZMod 8 and let decide exhaust all 8^3 residue triples, none summing to 7. |
| title | A sum of three integer squares is never congruent to 7 modulo 8 (a case of the three-square theorem). |

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
   python3 -m tools.upstream.raise_pr --goal sum-three-squares-zmod-eight-ne-seven --fork <your-github-user> --understood
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
