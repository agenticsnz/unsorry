# sum-range-pow-five-faulhaber-triangular

For every natural n, 3·(sum of i⁵ for i in 0..n) = (sum of i for i in 0..n)²·(4·(sum of i for i in 0..n)−1); i.e. ∑k⁵ = T²(4T−1)/3 where T = ∑k. Faulhaber's theorem made concrete: the fifth-power sum is a pure polynomial in the triangular number T.

- **Source:** classic identities (Faulhaber-in-T tower — odd-power rung; compounds on `sum-range-pow-five-closed-form`)
- **Reference:** Faulhaber's 1631 result that odd-power sums are polynomials in T = n(n+1)/2: ∑k⁵ = (4T³−T²)/3 = T²(4T−1)/3. Knuth, "Johann Faulhaber and sums of powers", Math. Comp. 61 (1993).
- **Absence:** machine-checked no-local-match (grep of pinned mathlib rev c5ea00351c28, 2026-06-13); the `i^5` flag resolves only to the general Bernoulli formula, not the T-form.
- **Difficulty:** 3
- **Decomposition sketch:** Substitute the proved `sum-range-pow-five-closed-form` (12∑k⁵ = n²(n+1)²(2n²+2n−1)) and the Gauss sum T = n(n+1)/2 — then T²(4T−1) = n²(n+1)²(2n²+2n−1)/4 = 3∑k⁵, a polynomial identity closed by ring (cleanest over ℚ, or ℕ with the proved form). The `4T−1` truncation is safe (T≥1 for n≥1; n=0 both sides 0). 1–2 steps. **Together with `sum-range-pow-seven-faulhaber-triangular`, this explains the power tower's crown: 3(∑k⁵+∑k⁷) = T²(4T−1)+T²(6T²−4T+1) = 6T⁴, i.e. ∑k⁵+∑k⁷ = 2T⁴.**
