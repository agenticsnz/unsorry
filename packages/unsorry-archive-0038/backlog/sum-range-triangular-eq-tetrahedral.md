# sum-range-triangular-eq-tetrahedral

6·∑_{k=0}^{n} k(k+1)/2 = n(n+1)(n+2) — sum of triangular numbers is tetrahedral.

- **Source:** Classic combinatorial / finite-sum identity (library-growth batch, #400 plan Phase 3).
- **Reference:** 6·∑_{k=0}^{n} k(k+1)/2 = n(n+1)(n+2) — sum of triangular numbers is tetrahedral. Not a named mathlib lemma (Vandermonde/Pascal are present but not these specific closed forms).
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035) — an unbounded ∑/∏ over a free n that the one-shot battery cannot close (and `simp`/`aesop` over full Mathlib did not find a renamed duplicate).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 3
- **Decomposition sketch:** induction + Finset.sum_range_succ; k(k+1) is even so /2 is exact. Concrete cases verified.
