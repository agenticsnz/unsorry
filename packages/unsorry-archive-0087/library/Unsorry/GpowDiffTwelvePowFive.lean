import Mathlib

theorem gpow_diff_twelve_pow_five (n : ℤ) : (n - 12) ∣ (n^5 - 248832) := by
  exact ⟨n^4 + 12*n^3 + 144*n^2 + 1728*n + 20736, by ring⟩
