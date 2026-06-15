# sum-range-pow-five-add-pow-seven

For every natural n, (sum of i⁵ for i in 0..n) + (sum of i⁷ for i in 0..n) = 2·(sum of i for i in 0..n)⁴; i.e. ∑k⁵ + ∑k⁷ = 2(∑k)⁴ = 2T⁴ where T = n(n+1)/2 is the n-th triangular number.

- **Source:** classic identities (power-sum tower — the **crown**: compounds on `sum-range-pow-five-closed-form` + `sum-range-pow-seven-closed-form`)
- **Reference:** A classic Faulhaber curiosity: the sum of the fifth- and seventh-power sums is exactly twice the fourth power of the triangular number, generalising Nicomachus's ∑k³ = (∑k)² = T² one octave up. Verified ∀ n; see Knuth, "Johann Faulhaber and sums of powers", Math. Comp. 61 (1993) for the triangular-number structure of odd-power sums.
- **Absence:** machine-checked no-local-match (grep of pinned mathlib rev c5ea00351c28, 2026-06-13)
- **Difficulty:** 4
- **Decomposition sketch:** **Two routes, both compounding.** (a) Substitute the proved/sourced closed forms for ∑k⁵ (`sum-range-pow-five-closed-form`) and ∑k⁷ (`sum-range-pow-seven-closed-form`) together with the Gauss sum ∑k = n(n+1)/2, then the goal is a polynomial identity in n closed by ring. (b) Direct induction on n: the step needs ∑_{≤n} k = n(n+1)/2 (Gauss) substituted into 2((T+(n+1))⁴ − T⁴) = (n+1)⁵+(n+1)⁷, then ring. Route (a) is the headline stack — it consumes two lower rungs of this very batch. No truncated subtraction in the statement (all terms are sums of positive powers), so `ring` over ℕ applies once the sums are unfolded.
