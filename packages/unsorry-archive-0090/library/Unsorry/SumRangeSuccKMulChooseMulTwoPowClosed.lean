import Mathlib

open Finset

/-- The weighted binomial sum `∑ C(n,k) 2^k = 3^n` (binomial theorem at `x = 2`,
`y = 1`). Helper for `sum_range_succ_k_mul_choose_mul_two_pow_closed`. -/
private theorem sum_range_choose_two_pow (n : ℕ) :
    ∑ k ∈ range (n + 1), n.choose k * 2 ^ k = 3 ^ n := by
  have h := add_pow (2 : ℕ) 1 n
  simp only [one_pow, mul_one, Nat.cast_id] at h
  rw [show ((2 : ℕ) + 1) = 3 from rfl] at h
  rw [h]
  exact Finset.sum_congr rfl fun k _ => by ring

/-- The first-moment sum `∑ k C(n+1,k) 2^k = 2 (n+1) 3^n`. Proved by peeling the
`k = 0` term and reindexing with `k C(n+1,k) = (n+1) C(n,k-1)`
(`Nat.succ_mul_choose_eq`), which avoids natural subtraction. -/
private theorem sum_range_k_mul_choose_two_pow (m : ℕ) :
    ∑ k ∈ range (m + 1 + 1), k * (m + 1).choose k * 2 ^ k = 2 * (m + 1) * 3 ^ m := by
  rw [Finset.sum_range_succ']
  simp only [zero_mul, add_zero]
  rw [← sum_range_choose_two_pow m, Finset.mul_sum]
  refine Finset.sum_congr rfl fun i _ => ?_
  have hp : (i + 1) * (m + 1).choose (i + 1) = (m + 1) * m.choose i := by
    rw [mul_comm]; exact (Nat.add_one_mul_choose_eq m i).symm
  calc (i + 1) * (m + 1).choose (i + 1) * 2 ^ (i + 1)
      = ((i + 1) * (m + 1).choose (i + 1)) * 2 ^ (i + 1) := by ring
    _ = ((m + 1) * m.choose i) * 2 ^ (i + 1) := by rw [hp]
    _ = 2 * (m + 1) * (m.choose i * 2 ^ i) := by rw [pow_succ]; ring

/-- Goal `sum-range-succ-k-mul-choose-mul-two-pow-closed`: three times the
weighted binomial sum `∑ (k+1) C(n,k) 2^k` equals `(2n+3) 3^n`. See
`library/index/`. The `3 ×` clears the `3^(n-1)` that the first moment carries.
-/
theorem sum_range_succ_k_mul_choose_mul_two_pow_closed (n : ℕ) :
    3 * ∑ k ∈ Finset.range (n + 1), (k + 1) * n.choose k * 2 ^ k = (2 * n + 3) * 3 ^ n := by
  have hsplit : ∑ k ∈ range (n + 1), (k + 1) * n.choose k * 2 ^ k
      = (∑ k ∈ range (n + 1), k * n.choose k * 2 ^ k)
        + ∑ k ∈ range (n + 1), n.choose k * 2 ^ k := by
    rw [← Finset.sum_add_distrib]
    exact Finset.sum_congr rfl fun k _ => by ring
  rw [hsplit, sum_range_choose_two_pow n]
  cases n with
  | zero => simp
  | succ m =>
    rw [sum_range_k_mul_choose_two_pow m, pow_succ]
    ring
