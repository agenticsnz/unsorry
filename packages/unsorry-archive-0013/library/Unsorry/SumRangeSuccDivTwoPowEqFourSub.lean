import Mathlib

set_option linter.unusedTactic false in
set_option linter.unreachableTactic false in
set_option linter.unusedVariables false in
theorem sum_range_succ_div_two_pow_eq_four_sub (n : ℕ) : ∑ k ∈ Finset.range n, ((k : ℚ) + 1) / 2 ^ k = 4 - (2 * (n : ℚ) + 4) / 2 ^ n := by
  induction n with
  | zero => first | rfl | simp | norm_num | decide | (simp [Finset.sum_range_zero, Finset.sum_range_one]) | (norm_num [Finset.sum_range_zero])
  | succ n ih =>
    (first
      | rw [Finset.sum_range_succ, ih]
      | rw [Finset.sum_range_succ, mul_add, ih]
      | rw [Finset.sum_range_succ, Finset.mul_sum, ih]
      | (rw [Finset.sum_range_succ]; rw [ih])
      | simp only [Finset.sum_range_succ, ih])
    first
      | (push_cast [pow_succ]; ring)
      | (push_cast; ring)
      | ring
      | (rw [pow_succ]; field_simp; ring)
      | (field_simp; ring)
      | (push_cast [Nat.factorial_succ, pow_succ]; ring)
      | (simp [Nat.factorial_succ, pow_succ]; ring)
      | omega
      | (push_cast; nlinarith [sq_nonneg (n : ℤ), Nat.zero_le n])
