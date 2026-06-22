import Mathlib

theorem gpow_diff_twelve_pow_four (n : ℤ) : (n - 12) ∣ (n^4 - 20736) := by
  exact ⟨n^3 + 12*n^2 + 144*n + 1728, by ring⟩
