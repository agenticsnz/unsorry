import Mathlib

theorem gpow_diff_nine_pow_eleven (n : ℤ) : (n - 9) ∣ (n^11 - 31381059609) := by
  exact ⟨n^10 + 9*n^9 + 81*n^8 + 729*n^7 + 6561*n^6 + 59049*n^5 + 531441*n^4 + 4782969*n^3 + 43046721*n^2 + 387420489*n + 3486784401, by ring⟩
