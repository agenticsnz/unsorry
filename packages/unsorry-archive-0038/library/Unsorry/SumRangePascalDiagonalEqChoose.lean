import Mathlib

theorem sum_range_pascal_diagonal_eq_choose (m n : ℕ) : ∑ k ∈ Finset.range (n + 1), (m + k).choose k = (m + n + 1).choose n := by
  have h : ∀ k, (m + k).choose k = (k + m).choose m := by
    intro k
    rw [Nat.add_comm m k]
    exact Nat.choose_symm_of_eq_add rfl
  simp_rw [h]
  rw [Nat.sum_range_add_choose n m]
  rw [show n + m + 1 = m + n + 1 by ring]
  exact (Nat.choose_symm_of_eq_add (by ring)).symm