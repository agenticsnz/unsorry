import Mathlib

theorem gpow_diff_twelve_pow_twelve (n : ℤ) : (n - 12) ∣ (n^12 - 8916100448256) := by
  exact ⟨n^11 + 12*n^10 + 144*n^9 + 1728*n^8 + 20736*n^7 + 248832*n^6 + 2985984*n^5 + 35831808*n^4 + 429981696*n^3 + 5159780352*n^2 + 61917364224*n + 743008370688, by ring⟩
