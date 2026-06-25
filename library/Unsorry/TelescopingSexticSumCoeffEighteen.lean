import Mathlib

/-- Goal `telescoping-sextic-sum-coeff-eighteen`: telescoping power-sum closed form, by induction on `n`. -/
theorem telescoping_sextic_sum_coeff_eighteen (n : ℕ) : ∑ k ∈ Finset.range n, (18 * (6 * (k : ℤ) ^ 5 + 15 * (k : ℤ) ^ 4 + 20 * (k : ℤ) ^ 3 + 15 * (k : ℤ) ^ 2 + 6 * (k : ℤ) + 1)) = 18 * (n : ℤ) ^ 6 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, ih]; push_cast; ring
