import Mathlib

theorem gpow_sum_twelve_pow_seven (n : ℤ) : (n + 12) ∣ (n^7 + 35831808) := by
  exact ⟨n^6 - 12*n^5 + 144*n^4 - 1728*n^3 + 20736*n^2 - 248832*n + 2985984, by ring⟩
