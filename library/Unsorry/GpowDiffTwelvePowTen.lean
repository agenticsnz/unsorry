import Mathlib

theorem gpow_diff_twelve_pow_ten (n : ℤ) : (n - 12) ∣ (n^10 - 61917364224) := by
  exact ⟨n^9 + 12*n^8 + 144*n^7 + 1728*n^6 + 20736*n^5 + 248832*n^4 + 2985984*n^3 + 35831808*n^2 + 429981696*n + 5159780352, by ring⟩
