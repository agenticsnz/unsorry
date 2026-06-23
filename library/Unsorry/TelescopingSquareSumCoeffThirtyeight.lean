import Mathlib

/-- Goal `telescoping-square-sum-coeff-thirtyeight`: telescoping power-sum closed form, by induction on `n`. -/
theorem telescoping_square_sum_coeff_thirtyeight (n : ℕ) : ∑ k ∈ Finset.range n, (2 * 38 * (k : ℤ) + 38) = 38 * (n : ℤ) ^ 2 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, ih]; push_cast; ring
