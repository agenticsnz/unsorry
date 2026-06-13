# sum-range-id-eq-choose-two

For every natural n, ∑_{i<n} i = C(n, 2): the Gauss sum 0 + 1 + ⋯ + (n−1) equals the binomial coefficient 'n choose 2'.

- **Source:** Gauss summation as a binomial coefficient
- **Reference:** The handshake identity ∑k = C(n,2); Graham, Knuth & Patashnik, Concrete Mathematics, §1. mathlib has `Finset.sum_range_id` and `Nat.choose_two_right` as separate closed forms (both n(n-1)/2) but not the theorem equating them.
- **Absence:** no-local-match — the two closed forms exist separately, the equating bridge does not (grep of pinned mathlib rev c5ea00351c, 2026-06-13)
- **Difficulty:** 2
- **Decomposition sketch:** L1 rw `Finset.sum_range_id` (or Gauss_sum) to n(n-1)/2. L2 rw `Nat.choose_two_right` to n(n-1)/2. L3 close by rfl/omega — a genuine Post(A) ⊆ Pre(B) bridge between two existing mathlib closed forms (a clean compounding canary).
