# sum-range-pow-five-closed-form

For every natural n, 12 * (sum of i^5 for i in 0..n) = n^2 (n+1)^2 (2n^2 + 2n - 1); Faulhaber's closed form for fifth powers, ∑k^5 = (2n^6 + 6n^5 + 5n^4 - n^2)/12.

- **Source:** classic identities
- **Reference:** Faulhaber's formula, p = 5 case; Conway & Guy, The Book of Numbers (sums of powers); D. E. Knuth, "Johann Faulhaber and sums of powers", Math. Comp. 61 (1993); CRC Standard Mathematical Tables.
- **Absence:** machine-checked; the `^ 5` pattern flags only Szemerédi-regularity bound files (Combinatorics/SimpleGraph/Regularity), verified unrelated — no Faulhaber p=5 closed form present (rev c5ea00351c28, 2026-06-12). Companion of the proved sum-range-pow-four-closed-form.
- **Difficulty:** 3
- **Decomposition sketch:** Induction on n over Finset.range (n+1) with Finset.sum_range_succ, mirroring the proved pow-four goal; the step is a degree-6 polynomial identity closed by ring after rewriting 2*(n+1)^2 + 2*(n+1) - 1 = 2*n^2 + 6*n + 3 to avoid truncated subtraction. 1-2 steps.
