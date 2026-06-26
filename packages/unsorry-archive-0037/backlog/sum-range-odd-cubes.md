# sum-range-odd-cubes

∑_{k=0}^{n-1} (2k+1)³ = n²(2n²−1) — the closed form for the sum of the first n odd cubes.

- **Source:** Classic combinatorial / finite-sum identity (library-growth batch, #400 plan Phase 3).
- **Reference:** ∑_{k=0}^{n-1} (2k+1)³ = n²(2n²−1) — the closed form for the sum of the first n odd cubes. Not a named mathlib lemma (Vandermonde/Pascal are present but not these specific closed forms).
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035) — an unbounded ∑/∏ over a free n that the one-shot battery cannot close (and `simp`/`aesop` over full Mathlib did not find a renamed duplicate).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 3
- **Decomposition sketch:** induction + Finset.sum_range_succ. Concrete cases verified.
