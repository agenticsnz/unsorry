import Mathlib

/-- Goal `telescoping-square-sum-coeff-fiftyeight`: telescoping power-sum closed form, by induction on `n`. -/
theorem telescoping_square_sum_coeff_fiftyeight (n : ℕ) : ∑ k ∈ Finset.range n, (2 * 58 * (k : ℤ) + 58) = 58 * (n : ℤ) ^ 2 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, ih]; push_cast; ring
