import Mathlib

theorem ggeom_pred_pow_four_sub_one (n : ℤ) : (n - 1) ∣ (n^4 - 1) := by
  exact ⟨n^3 + n^2 + n + 1, by ring⟩
