import Mathlib

theorem sum_range_disp_mul_choose_eq_zero (n : ℕ) : ∑ k ∈ Finset.range (n + 1), (2 * (k : ℤ) - n) * (n.choose k : ℤ) = 0 := by
  have h1 : ∀ k : ℕ, (2 * (k : ℤ) - n) * (n.choose k : ℤ)
      = 2 * ((k * n.choose k : ℕ) : ℤ) - n * ((n.choose k : ℕ) : ℤ) := by
    intro k; push_cast; ring
  simp_rw [h1]
  rw [Finset.sum_sub_distrib, ← Finset.mul_sum, ← Finset.mul_sum]
  rw [← Nat.cast_sum, ← Nat.cast_sum, Nat.sum_range_mul_choose, Nat.sum_range_choose]
  cases n with
  | zero => simp
  | succ m =>
    push_cast
    ring