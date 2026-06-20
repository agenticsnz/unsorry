import Mathlib

theorem gpow_diff_twelve_pow_eleven (n : ℤ) : (n - 12) ∣ (n^11 - 743008370688) := by
  exact ⟨n^10 + 12*n^9 + 144*n^8 + 1728*n^7 + 20736*n^6 + 248832*n^5 + 2985984*n^4 + 35831808*n^3 + 429981696*n^2 + 5159780352*n + 61917364224, by ring⟩
