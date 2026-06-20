import Mathlib

theorem sum_range_k_plus_one_mul_choose (n : ℕ) : 2 * ∑ k ∈ Finset.range (n + 1), (k + 1) * n.choose k = (n + 2) * 2 ^ n := by
  have hsplit : ∑ k ∈ Finset.range (n + 1), (k + 1) * n.choose k
      = (∑ k ∈ Finset.range (n + 1), k * n.choose k)
        + ∑ k ∈ Finset.range (n + 1), n.choose k := by
    rw [← Finset.sum_add_distrib]
    apply Finset.sum_congr rfl
    intro k _
    ring
  rw [hsplit, Nat.sum_range_mul_choose, Nat.sum_range_choose]
  cases n with
  | zero => simp
  | succ m =>
    simp only [Nat.add_sub_cancel]
    ring