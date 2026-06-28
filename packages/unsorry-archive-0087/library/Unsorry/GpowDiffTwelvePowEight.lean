import Mathlib

theorem gpow_diff_twelve_pow_eight (n : ℤ) : (n - 12) ∣ (n^8 - 429981696) := by
  exact ⟨n^7 + 12*n^6 + 144*n^5 + 1728*n^4 + 20736*n^3 + 248832*n^2 + 2985984*n + 35831808, by ring⟩
