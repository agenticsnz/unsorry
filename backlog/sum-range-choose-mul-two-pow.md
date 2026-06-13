# sum-range-choose-mul-two-pow

For every natural n, the sum over k in 0..n of C(n,k)·2ᵏ equals 3ⁿ; the binomial theorem at x=2: ∑C(n,k)2ᵏ = (1+2)ⁿ = 3ⁿ.

- **Source:** classic identities (binomial-moment tower — the weighted row sum)
- **Reference:** Specialisation of the binomial theorem (1+x)ⁿ = ∑C(n,k)xᵏ at x=2. Standard; Concrete Mathematics, Ch. 5.
- **Absence:** machine-checked no-local-match (grep of pinned mathlib rev c5ea00351c28, 2026-06-13); mathlib has the unweighted row sum `Nat.sum_range_choose` (∑C(n,k) = 2ⁿ) and the general `add_pow`, but not this x=2 specialisation as a named ℕ lemma.
- **Difficulty:** 2
- **Decomposition sketch:** Apply `add_pow` / `Commute.add_pow` with x=2, y=1 (or induct with Pascal's rule); 3ⁿ = (2+1)ⁿ. 1–2 steps.
