import Mathlib

/-- Goal `shift-square-sum-coeff-fortyeight`: shifted-square-sum closed form, by induction on `n`. -/
theorem shift_square_sum_coeff_fortyeight (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 48) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 48 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 48 ^ 2 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; push_cast; ring
