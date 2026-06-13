# sum-range-sq-triangular-form

For every natural n, 3·(sum of i² for i in 0..n) = (sum of i for i in 0..n)·(2n+1); i.e. ∑k² = T·(2n+1)/3 where T = ∑k = n(n+1)/2 is the n-th triangular number.

- **Source:** classic identities (Faulhaber-in-T tower — power sums as polynomials in the triangular number)
- **Reference:** Faulhaber's theorem: ∑kᵖ is a polynomial in T = n(n+1)/2; the even-power cases carry a factor (2n+1). ∑k² = n(n+1)(2n+1)/6 = T(2n+1)/3. Knuth, "Johann Faulhaber and sums of powers", Math. Comp. 61 (1993).
- **Absence:** machine-checked no-local-match (grep of pinned mathlib rev c5ea00351c28, 2026-06-13); mathlib carries only the general Bernoulli-number formula (`NumberTheory/Bernoulli.lean`, `sum_range_pow`), not the triangular-number form.
- **Difficulty:** 2
- **Decomposition sketch:** Compounds on the proved `sum-range-sq-closed-form` (6∑k² = n(n+1)(2n+1)) plus the Gauss sum ∑k = n(n+1)/2 (mathlib `Finset.sum_range_id`): substitute both and close by ring. Or direct induction. 1–2 steps. **This rung re-expresses a proved closed form in terms of T — the first step of revealing the Faulhaber structure.**
