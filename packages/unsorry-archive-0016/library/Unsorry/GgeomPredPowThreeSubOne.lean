import Mathlib

theorem ggeom_pred_pow_three_sub_one (n : ℤ) : (n - 1) ∣ (n^3 - 1) := by
  exact ⟨n^2 + n + 1, by ring⟩
