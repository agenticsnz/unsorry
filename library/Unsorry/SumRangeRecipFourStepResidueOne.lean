import Mathlib

theorem sum_range_recip_four_step_residue_one (n : ℕ) : ∑ k ∈ Finset.range n, (4 : ℚ) / ((4 * (k : ℚ) + 1) * (4 * (k : ℚ) + 5)) = 1 - 1 / (4 * (n : ℚ) + 1) := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, ih]
    have h1 : (4 * (m : ℚ) + 1) ≠ 0 := by positivity
    have h2 : (4 * (m : ℚ) + 5) ≠ 0 := by positivity
    have h3 : (4 * ((m : ℚ) + 1) + 1) ≠ 0 := by positivity
    push_cast
    field_simp
    ring