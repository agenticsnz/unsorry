import Mathlib

theorem sum_icc_choose_zero_right (r : ℕ) : ∑ k ∈ Finset.Icc r 0, k.choose r = (1 : ℕ).choose (r + 1) := by
  rcases Nat.eq_zero_or_pos r with hr | hr
  · subst hr; decide
  · have h1 : Finset.Icc r 0 = ∅ := by
      rw [Finset.Icc_eq_empty]; omega
    rw [h1, Finset.sum_empty]
    rw [Nat.choose_eq_zero_of_lt (by omega)]