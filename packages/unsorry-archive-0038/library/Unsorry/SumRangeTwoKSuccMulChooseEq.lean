import Mathlib

theorem sum_range_two_k_succ_mul_choose_eq (n : ℕ) : ∑ k ∈ Finset.range (n + 1), (2 * k + 1) * n.choose k = (n + 1) * 2 ^ n := by
  have hsplit : ∀ k, (2 * k + 1) * n.choose k = 2 * (k * n.choose k) + n.choose k := by
    intro k; ring
  simp_rw [hsplit]
  rw [Finset.sum_add_distrib, ← Finset.mul_sum, Nat.sum_range_mul_choose, Nat.sum_range_choose]
  cases n with
  | zero => simp
  | succ m =>
    simp only [Nat.add_sub_cancel]
    rw [pow_succ]
    ring