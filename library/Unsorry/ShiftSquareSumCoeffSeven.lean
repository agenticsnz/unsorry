import Mathlib

/-- Goal `shift-square-sum-coeff-seven`: shifted-square-sum closed form, by induction on `n`. -/
theorem shift_square_sum_coeff_seven (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 7) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 7 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 7 ^ 2 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; push_cast; ring
