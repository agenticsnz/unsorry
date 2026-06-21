import Mathlib

set_option linter.unusedTactic false in
set_option linter.unreachableTactic false in
theorem sum_centered_tetrahedral_closed_form (n : ℕ) :
    2 * ∑ k ∈ Finset.range n, (2 * (k:ℤ) + 1) * ((k:ℤ)^2 + k + 3)
      = (n:ℤ)^2 * ((n:ℤ)^2 + 5) := by
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
