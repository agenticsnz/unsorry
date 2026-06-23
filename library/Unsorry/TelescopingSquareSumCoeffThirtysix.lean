import Mathlib

/-- Goal `telescoping-square-sum-coeff-thirtysix`: telescoping power-sum closed form, by induction on `n`. -/
theorem telescoping_square_sum_coeff_thirtysix (n : ℕ) : ∑ k ∈ Finset.range n, (2 * 36 * (k : ℤ) + 36) = 36 * (n : ℤ) ^ 2 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, ih]; push_cast; ring
