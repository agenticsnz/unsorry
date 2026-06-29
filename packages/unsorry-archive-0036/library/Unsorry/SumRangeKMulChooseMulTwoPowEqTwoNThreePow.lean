import Mathlib

open Finset

theorem sum_range_k_mul_choose_mul_two_pow_eq_two_n_three_pow (n : ℕ) : 3 * ∑ k ∈ Finset.range (n + 1), k * n.choose k * 2 ^ k = 2 * n * 3 ^ n := by
  -- binomial helper
  have binom : ∀ m : ℕ, ∑ k ∈ range (m+1), m.choose k * 2 ^ k = 3 ^ m := by
    intro m
    have h := add_pow (2:ℕ) 1 m
    simp only [one_pow, mul_one, Nat.cast_id] at h
    rw [show (2:ℕ)+1 = 3 from rfl] at h
    rw [h]
    apply Finset.sum_congr rfl
    intro k hk
    ring
  cases n with
  | zero => simp
  | succ m =>
    -- The k=0 term is zero, so sum over range (m+2) = sum over range (m+1) reindexed
    rw [Finset.sum_range_succ']
    -- sum_range_succ' splits off the k=0 term at the start
    simp only [add_zero, Nat.choose_zero_right, pow_zero, mul_one]
    -- now sum is ∑ k ∈ range (m+1), (k+1) * C(m+1, k+1) * 2^(k+1)
    have key : ∀ k ∈ range (m+1), (k+1) * (m+1).choose (k+1) * 2^(k+1)
        = 2 * (m+1) * (m.choose k * 2^k) := by
      intro k hk
      have hc : (m+1) * m.choose k = (m+1).choose (k+1) * (k+1) :=
        Nat.add_one_mul_choose_eq m k
      have : (k+1) * (m+1).choose (k+1) = (m+1) * m.choose k := by
        rw [hc]; ring
      calc (k+1) * (m+1).choose (k+1) * 2^(k+1)
          = ((k+1) * (m+1).choose (k+1)) * 2^(k+1) := by ring
        _ = ((m+1) * m.choose k) * 2^(k+1) := by rw [this]
        _ = 2 * (m+1) * (m.choose k * 2^k) := by ring
    rw [Finset.sum_congr rfl key, ← Finset.mul_sum, binom m]
    ring