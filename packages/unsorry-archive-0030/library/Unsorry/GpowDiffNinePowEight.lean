import Mathlib

theorem gpow_diff_nine_pow_eight (n : ℤ) : (n - 9) ∣ (n^8 - 43046721) := by
  exact ⟨n^7 + 9*n^6 + 81*n^5 + 729*n^4 + 6561*n^3 + 59049*n^2 + 531441*n + 4782969, by ring⟩
