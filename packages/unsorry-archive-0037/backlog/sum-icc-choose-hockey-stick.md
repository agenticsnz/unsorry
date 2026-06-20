# sum-icc-choose-hockey-stick

The hockey-stick identity: ∑_{k=r}^{n} C(k,r) = C(n+1,r+1).

- **Source:** Classic combinatorial / finite-sum identity (library-growth batch, #400 plan Phase 3).
- **Reference:** The hockey-stick identity: ∑_{k=r}^{n} C(k,r) = C(n+1,r+1). Not a named mathlib lemma (Vandermonde/Pascal are present but not these specific closed forms).
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035) — an unbounded ∑/∏ over a free n that the one-shot battery cannot close (and `simp`/`aesop` over full Mathlib did not find a renamed duplicate).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 3
- **Decomposition sketch:** induction on n with Pascal's rule Nat.choose_succ_succ. Concrete cases verified.
