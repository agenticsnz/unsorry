import Mathlib

theorem gpow_diff_nine_pow_ten (n : ℤ) : (n - 9) ∣ (n^10 - 3486784401) := by
  exact ⟨n^9 + 9*n^8 + 81*n^7 + 729*n^6 + 6561*n^5 + 59049*n^4 + 531441*n^3 + 4782969*n^2 + 43046721*n + 387420489, by ring⟩
