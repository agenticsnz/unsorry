# sum-range-pow-seven-closed-form

For every natural n, 24·(sum of i⁷ for i in 0..n) = n²(n+1)²(3n⁴+6n³−n²−4n+2); Faulhaber's closed form for seventh powers, ∑k⁷ = (3n⁸+12n⁷+14n⁶−7n⁴+2n²)/24.

- **Source:** classic identities (power-sum tower — the harder odd-power rung)
- **Reference:** Faulhaber's formula, p = 7; Conway & Guy, The Book of Numbers; D. E. Knuth, "Johann Faulhaber and sums of powers", Math. Comp. 61 (1993). Faulhaber's own result: odd-power sums are polynomials in the triangular number T = n(n+1)/2.
- **Absence:** machine-checked; the `i ^ 7` pattern flags only elliptic-curve / modular-form files (AlgebraicGeometry/EllipticCurve, NumberTheory/ModularForms/DedekindEta), verified unrelated — no specific seventh-power Faulhaber closed form present (general Bernoulli formula only; rev c5ea00351c28, 2026-06-13).
- **Difficulty:** 4
- **Decomposition sketch:** Induction on n over Finset.range (n+1) with Finset.sum_range_succ; the step is a degree-8 polynomial identity closed by ring after clearing the truncated subtractions in 3(n+1)⁴+6(n+1)³−(n+1)²−4(n+1)+2 (the factor is ≥ 0 for all n; n=0 closes by rfl). 1–2 steps. Feeds the crown identity `sum-range-pow-five-add-pow-seven`.
