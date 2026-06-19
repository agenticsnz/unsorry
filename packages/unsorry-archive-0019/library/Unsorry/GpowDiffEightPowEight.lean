import Mathlib

theorem gpow_diff_eight_pow_eight (n : ℤ) : (n - 8) ∣ (n^8 - 16777216) := by
  exact ⟨n^7 + 8*n^6 + 64*n^5 + 512*n^4 + 4096*n^3 + 32768*n^2 + 262144*n + 2097152, by ring⟩
