# nat-sq-lt-two-pow

For every natural n ≥ 5, n² < 2ⁿ — the quadratic-vs-exponential crossover.

- **Source:** Classic crossover inequality (standard induction exercise)
- **Reference:** n² < 2ⁿ for n ≥ 5. mathlib has linear `Nat.lt_two_pow`-style bounds and Bernoulli (`one_add_mul_le_pow`) but no quadratic-vs-exponential crossover lemma.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035)
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14)
- **Difficulty:** 3
- **Decomposition sketch:** Two-layer induction (not one-shot-closable). L1 helper 2n+1 < n² for n≥3 (small induction / omega after bounding). L2 base n=5 (25<32) by decide/norm_num. L3 induction step: `pow_succ` gives 2^(n+1)=2·2^n, IH n²<2^n. L4 (n+1)² ≤ 2n² via L1, chain to < 2·2^n.
