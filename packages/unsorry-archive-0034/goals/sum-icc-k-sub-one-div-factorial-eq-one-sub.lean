import Mathlib

theorem sum_icc_k_sub_one_div_factorial_eq_one_sub (n : ℕ) (hn : 1 ≤ n) : (∑ k ∈ Finset.Icc 1 n, ((k : ℚ) - 1) / Nat.factorial k) = 1 - 1 / Nat.factorial n := by
  sorry
