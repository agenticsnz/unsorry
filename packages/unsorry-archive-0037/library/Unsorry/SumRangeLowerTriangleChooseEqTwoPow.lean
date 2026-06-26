import Mathlib

theorem sum_range_lower_triangle_choose_eq_two_pow (n : ℕ) : ∑ j ∈ Finset.range (n + 1), ∑ k ∈ Finset.range (j + 1), j.choose k = 2 ^ (n + 1) - 1 := by
  have h : ∀ j, ∑ k ∈ Finset.range (j + 1), j.choose k = 2 ^ j := by
    intro j
    simpa using Nat.sum_range_choose j
  simp_rw [h]
  simp [Nat.geomSum_eq (le_refl 2) (n + 1)]