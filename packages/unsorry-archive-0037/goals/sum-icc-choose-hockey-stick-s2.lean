import Mathlib

theorem sum_icc_choose_succ_right (n r : ℕ) : ∑ k ∈ Finset.Icc r (n + 1), k.choose r = (∑ k ∈ Finset.Icc r n, k.choose r) + (n + 1).choose r := by
  sorry
