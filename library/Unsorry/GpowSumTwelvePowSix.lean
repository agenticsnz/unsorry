import Mathlib

theorem gpow_sum_twelve_pow_six (n : ℤ) : (n + 12) ∣ (n^6 - 2985984) := by
  exact ⟨n^5 - 12*n^4 + 144*n^3 - 1728*n^2 + 20736*n - 248832, by ring⟩
