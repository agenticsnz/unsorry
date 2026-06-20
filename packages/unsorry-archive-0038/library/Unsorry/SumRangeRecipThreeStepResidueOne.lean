import Mathlib

theorem sum_range_recip_three_step_residue_one (n : ℕ) : ∑ k ∈ Finset.range n, (3 : ℚ) / ((3 * (k : ℚ) + 1) * (3 * (k : ℚ) + 4)) = 1 - 1 / (3 * (n : ℚ) + 1) := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, ih]
    have h1 : (3 * (m : ℚ) + 1) ≠ 0 := by positivity
    have h2 : (3 * (m : ℚ) + 4) ≠ 0 := by positivity
    have h3 : (3 * ((m : ℚ) + 1) + 1) ≠ 0 := by positivity
    push_cast
    field_simp
    ring