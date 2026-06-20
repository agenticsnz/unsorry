import Mathlib

theorem gpow_diff_nine_pow_nine (n : ℤ) : (n - 9) ∣ (n^9 - 387420489) := by
  exact ⟨n^8 + 9*n^7 + 81*n^6 + 729*n^5 + 6561*n^4 + 59049*n^3 + 531441*n^2 + 4782969*n + 43046721, by ring⟩
