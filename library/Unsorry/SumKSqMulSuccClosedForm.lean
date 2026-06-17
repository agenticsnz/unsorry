import Mathlib

set_option linter.unusedTactic false in
set_option linter.unreachableTactic false in
theorem sum_k_sq_mul_succ_closed_form (n : ℕ) : 12 * ∑ k ∈ Finset.range (n + 1), k ^ 2 * (k + 1) = n * (n + 1) * (n + 2) * (3 * n + 1) := by
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
