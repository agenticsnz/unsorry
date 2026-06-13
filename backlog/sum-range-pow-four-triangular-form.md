# sum-range-pow-four-triangular-form

For every natural n, 15·(sum of i⁴ for i in 0..n) = (sum of i for i in 0..n)·(2n+1)·(3n²+3n−1); i.e. ∑k⁴ = T(2n+1)(3n²+3n−1)/15 where T = ∑k.

- **Source:** classic identities (Faulhaber-in-T tower — even-power rung)
- **Reference:** Faulhaber's theorem, even-power case: ∑k⁴ = n(n+1)(2n+1)(3n²+3n−1)/30 = T(2n+1)(3n²+3n−1)/15. Knuth, "Johann Faulhaber and sums of powers", Math. Comp. 61 (1993); CRC Standard Mathematical Tables.
- **Absence:** machine-checked no-local-match (grep of pinned mathlib rev c5ea00351c28, 2026-06-13); only the general Bernoulli formula is present.
- **Difficulty:** 3
- **Decomposition sketch:** Compounds on the proved `sum-range-pow-four-closed-form` plus the Gauss sum; substitute and close by ring after clearing the (3n²+3n−1) truncated subtraction (n=0 closes by rfl). 1–2 steps. Contrasts the odd-power rungs: even powers keep the extra (2n+1) factor, odd powers reduce to pure powers of T.
