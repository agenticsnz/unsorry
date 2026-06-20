import Mathlib

theorem two_mul_sum_icc_three_k_sub_two_eq_pentagonal (n : ℕ) : 2 * ∑ k ∈ Finset.Icc 1 n, (3 * k - 2) = n * (3 * n - 1) := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_Icc_succ_top (by omega), Nat.mul_add, ih]
    have h1 : 3 * (m + 1) - 2 = 3 * m + 1 := by omega
    rw [h1]
    cases m with
    | zero => simp
    | succ p =>
      have : 3 * (p + 1 + 1) - 1 = 3 * p + 5 := by omega
      rw [this]
      have h2 : 3 * (p + 1) - 1 = 3 * p + 2 := by omega
      rw [h2]
      ring