import Mathlib

set_option linter.unusedTactic false in
set_option linter.unreachableTactic false in
theorem sum_icc_five_k_sub_two_mul_three_pow_pred_closed (n : ℕ) :
    4 * ∑ k ∈ Finset.Icc 1 n, ((5 * (k : ℤ) - 2) * 3 ^ (k - 1)) =
      (10 * (n : ℤ) - 9) * 3 ^ n + 9 := by
  induction n with
  | zero => first | simp | norm_num | (simp; ring) | (simp; norm_num) | (simp; rfl)
  | succ n ih =>
    first
      | (rw [Finset.sum_Icc_succ_top (by omega), ih]; ring)
      | (rw [Finset.sum_Icc_succ_top (by omega)]; linear_combination ih)
      | (rw [Finset.sum_Icc_succ_top (by omega)]; push_cast; linear_combination ih)
      | (rw [Finset.sum_Icc_succ_top (by omega)]; nlinarith [ih])
      | (rw [Finset.sum_Icc_succ_top (by omega), Nat.mul_add, ih]; ring)
      | (rw [Finset.prod_Icc_succ_top (by omega)]; rw [ih]; ring)
      | (rw [Finset.prod_Icc_succ_top (by omega)]; rw [ih]; field_simp; ring)
      | (rw [Finset.prod_Icc_succ_top (by omega)]; rw [ih]; push_cast; field_simp; ring)
