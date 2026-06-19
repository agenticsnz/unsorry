import Mathlib

theorem ggeom_pred_pow_six_sub_one (n : ℤ) : (n - 1) ∣ (n^6 - 1) := by
  exact ⟨n^5 + n^4 + n^3 + n^2 + n + 1, by ring⟩
