# Upstream packet: `quartic-four-var-ge-four-prod`

Status: packet-ready · generated mechanically (ADR-020 / SPEC-020-A) · sponsor: Chris Barlow

## The statement (as proved here)

```lean
import Mathlib

theorem quartic_four_var_ge_four_prod (a b c d : ℝ) : 4*a*b*c*d ≤ a^4 + b^4 + c^4 + d^4 := by
  sorry
```

Kernel-verified on `main`: `library/Unsorry/QuarticFourVarGeFourProd.lean` (theorem `quartic_four_var_ge_four_prod`),
through Gate A (build `--wfail`, axiom audit against the standard whitelist, leanchecker
kernel replay, regenerated ADR-011 binding obligation).

## Proposed contribution

The `git apply`-able new-file diff is at [`quartic-four-var-ge-four-prod.patch`](quartic-four-var-ge-four-prod.patch). The target path
`Mathlib/Unsorry/QuarticFourVarGeFourProd.lean` is a **placeholder** — file placement and the
final name are Zulip questions, not ours to decide. Content:

```lean
/-
Copyright (c) 2026 Chris Barlow. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Chris Barlow
-/
import Mathlib

theorem quartic_four_var_ge_four_prod (a b c d : ℝ) :
    4 * a * b * c * d ≤ a ^ 4 + b ^ 4 + c ^ 4 + d ^ 4 := by
  nlinarith [sq_nonneg (a ^ 2 - b ^ 2), sq_nonneg (c ^ 2 - d ^ 2), sq_nonneg (a * b - c * d),
    sq_nonneg (a * b + c * d)]
```

## Dedup at mathlib HEAD

- mathlib revision scanned: `2216b5b1ea909cc6bcd2c3b45516c1ece827135f`
- patterns: `\bquartic_four_var_ge_four_prod\b`
- verdict: **no-local-match**
- matches:
- none

A name-grep is a pre-filter, not a proof of absence; the kernel build at HEAD
(`tools/upstream/verify_head.sh`) is the strong evidence and its result belongs in the
PR conversation.

## Provenance dossier

| Field | Value |
|---|---|
| source | #400 Identity Engine (ADR-043/ADR-060) — classical 2–3 variable SOS / competition inequalities; promoted from backlog/candidates/sos-inequalities.md. |
| reference | Four-variable AM–GM instance. Not a named mathlib lemma in this form. |
| absence | no-local-match (grep over pinned mathlib c5ea00351c, structural a,b,c expression patterns); mathlib_rev c5ea00351c28e24afc9f0f84379aa41082b1188f; 2026-06-17 |
| triviality | non-trivial (ADR-035 battery v1: rfl/trivial/decide/norm_num/omega/simp/simp_all/aesop/ring/linarith/tauto — none close a multivariate SOS inequality; nlinarith/positivity excluded by design); rev c5ea00351c; 2026-06-17 |
| difficulty | 3 |
| decomposition sketch | Chain a^4+b^4≥2a^2b^2, c^4+d^4≥2c^2d^2, and 2a^2b^2+2c^2d^2≥4abcd. Verified to compile: `nlinarith [sq_nonneg (a^2-b^2), sq_nonneg (c^2-d^2), sq_nonneg (a*b-c*d), sq_nonneg (a*b+c*d)]`. |
| title | Four-variable AM–GM on fourth powers: for all reals, a⁴+b⁴+c⁴+d⁴ ≥ 4abcd. |

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
   python3 -m tools.upstream.raise_pr --goal quartic-four-var-ge-four-prod --fork <your-github-user> --understood
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
