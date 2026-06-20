# Upstream packet: `fourth-power-mod-fortyone-mem`

Status: packet-ready · generated mechanically (ADR-020 / SPEC-020-A) · sponsor: Chris Barlow

## The statement (as proved here)

```lean
import Mathlib

theorem fourth_power_mod_fortyone_mem (r : ℕ) (hr : r < 41) : (∃ n : ℕ, n ^ 4 % 41 = r) ↔ r ∈ ({0, 1, 4, 10, 16, 18, 23, 25, 31, 37, 40} : Finset ℕ) := by
  sorry
```

Kernel-verified on `main`: `library/Unsorry/FourthPowerModFortyoneMem.lean` (theorem `fourth_power_mod_fortyone_mem`),
through Gate A (build `--wfail`, axiom audit against the standard whitelist, leanchecker
kernel replay, regenerated ADR-011 binding obligation).

## Proposed contribution

The `git apply`-able new-file diff is at [`fourth-power-mod-fortyone-mem.patch`](fourth-power-mod-fortyone-mem.patch). The target path
`Mathlib/Unsorry/FourthPowerModFortyoneMem.lean` is a **placeholder** — file placement and the
final name are Zulip questions, not ours to decide. Content:

```lean
/-
Copyright (c) 2026 Chris Barlow. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Chris Barlow
-/
import Mathlib

theorem fourth_power_mod_fortyone_mem (r : ℕ) (hr : r < 41) : (∃ n : ℕ, n ^ 4 % 41 = r) ↔ r ∈ ({0, 1, 4, 10, 16, 18, 23, 25, 31, 37, 40} : Finset ℕ) := by
  constructor
  · rintro ⟨n, rfl⟩
    have h : n ^ 4 % 41 = (n % 41) ^ 4 % 41 := by
      rw [Nat.pow_mod]
    rw [h]
    have hlt : n % 41 < 41 := Nat.mod_lt _ (by norm_num)
    interval_cases (n % 41) <;> decide
  · intro hr2
    fin_cases hr2
    · exact ⟨0, by decide⟩
    · exact ⟨1, by decide⟩
    · exact ⟨11, by decide⟩
    · exact ⟨4, by decide⟩
    · exact ⟨2, by decide⟩
    · exact ⟨16, by decide⟩
    · exact ⟨7, by decide⟩
    · exact ⟨6, by decide⟩
    · exact ⟨12, by decide⟩
    · exact ⟨8, by decide⟩
    · exact ⟨3, by decide⟩
```

## Dedup at mathlib HEAD

- mathlib revision scanned: `2216b5b1ea909cc6bcd2c3b45516c1ece827135f`
- patterns: `\bfourth_power_mod_fortyone_mem\b`
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
| reference | The fourth-power residues modulo the prime 41 are exactly {0,1,4,10,16,18,23,25,31,37,40}. Not a named mathlib lemma in this form. |
| absence | no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd). |
| triviality | machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15). |
| difficulty | 2 |
| decomposition sketch | 4 | 40 gives only 11 quartic residues; Nat.pow_mod and decide over n % 41 with raised maxRecDepth. Verified to build (lake env lean) at sourcing. |
| title | The fourth-power residues modulo the prime 41 are exactly {0,1,4,10,16,18,23,25,31,37,40}. |

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
   python3 -m tools.upstream.raise_pr --goal fourth-power-mod-fortyone-mem --fork <your-github-user> --understood
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
