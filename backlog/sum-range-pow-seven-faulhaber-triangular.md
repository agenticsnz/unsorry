# sum-range-pow-seven-faulhaber-triangular

For every natural n, 3·(sum of i⁷ for i in 0..n) = (sum of i for i in 0..n)²·(6·(sum of i for i in 0..n)²−4·(sum of i for i in 0..n)+1); i.e. ∑k⁷ = T²(6T²−4T+1)/3 where T = ∑k. The seventh-power sum as a pure polynomial in the triangular number.

- **Source:** classic identities (Faulhaber-in-T tower — the **capstone** odd-power rung; compounds on `sum-range-pow-seven-closed-form`)
- **Reference:** Faulhaber's theorem for p=7: ∑k⁷ = (6T⁴−4T³+T²)/3 = T²(6T²−4T+1)/3. Knuth, "Johann Faulhaber and sums of powers", Math. Comp. 61 (1993).
- **Absence:** machine-checked; the `i^7` flag resolves only to elliptic-curve coefficient code (Weierstrass normal forms), not a power-sum identity (rev c5ea00351c28, 2026-06-13).
- **Difficulty:** 4
- **Decomposition sketch:** Substitute the sourced `sum-range-pow-seven-closed-form` (24∑k⁷ = n²(n+1)²(3n⁴+6n³−n²−4n+2)) and the Gauss sum T = n(n+1)/2, then close the polynomial identity by ring (cleanest over ℚ). The nested truncations in 6T²−4T+1 are safe for all n. 1–2 steps. **The other half of the crown's explanation:** 3∑k⁵ + 3∑k⁷ = T²(4T−1) + T²(6T²−4T+1) = 6T⁴, recovering `sum-range-pow-five-add-pow-seven` (∑k⁵+∑k⁷ = 2T⁴) as a corollary.
