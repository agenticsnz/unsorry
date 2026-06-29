import Mathlib

theorem gpow_sum_twelve_pow_nine (n : ℤ) : (n + 12) ∣ (n^9 + 5159780352) := by
  exact ⟨n^8 - 12*n^7 + 144*n^6 - 1728*n^5 + 20736*n^4 - 248832*n^3 + 2985984*n^2 - 35831808*n + 429981696, by ring⟩
