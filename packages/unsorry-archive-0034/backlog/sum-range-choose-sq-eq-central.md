# sum-range-choose-sq-eq-central

∑_{k=0}^{n} C(n,k)² = C(2n,n) — the central-binomial Vandermonde identity.

- **Source:** Classic combinatorial / finite-sum identity (library-growth batch, #400 plan Phase 3).
- **Reference:** ∑_{k=0}^{n} C(n,k)² = C(2n,n) — the central-binomial Vandermonde identity. Not a named mathlib lemma (Vandermonde/Pascal are present but not these specific closed forms).
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035) — an unbounded ∑/∏ over a free n that the one-shot battery cannot close (and `simp`/`aesop` over full Mathlib did not find a renamed duplicate).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 4
- **Decomposition sketch:** Vandermonde: C(n,k)²=C(n,k)C(n,n−k), sum = C(2n,n). Concrete cases verified.
