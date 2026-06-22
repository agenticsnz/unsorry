import Mathlib

set_option linter.unusedTactic false in
set_option linter.unreachableTactic false in
theorem sum_centered_cube_eq_biquadratic (n : ℕ) : 2 * ∑ k ∈ Finset.range n, (k ^ 3 + (k + 1) ^ 3) = n ^ 2 * (n ^ 2 + 1) := by
  induction n with
  | zero =>
    first | rfl | simp | norm_num | (simp; ring) | (simp; norm_num) | norm_num [Finset.sum_range_succ, Finset.prod_range_succ]
  | succ n ih =>
    first
      | (rw [Finset.sum_range_succ, ih]; ring)
      | (rw [Finset.sum_range_succ]; linear_combination ih)
      | (rw [Finset.sum_range_succ]; push_cast; linear_combination ih)
      | (rw [Finset.sum_range_succ]; nlinarith [ih])
      | (rw [Finset.sum_range_succ, Nat.mul_add, ih]; ring)
      | (rw [Finset.sum_range_succ]; push_cast; field_simp; linear_combination ih)
      | (rw [Finset.sum_range_succ]; field_simp; linear_combination ih)
      | (rw [Finset.prod_range_succ, ih]; ring)
      | (rw [Finset.prod_range_succ]; rw [ih]; ring)
      | (rw [Finset.prod_range_succ]; push_cast; field_simp; ring)
      | (simp only [Finset.sum_range_succ, ih]; ring)
