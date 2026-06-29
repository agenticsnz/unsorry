import Mathlib

theorem gpow_diff_nine_pow_seven (n : ℤ) : (n - 9) ∣ (n^7 - 4782969) := by
  exact ⟨n^6 + 9*n^5 + 81*n^4 + 729*n^3 + 6561*n^2 + 59049*n + 531441, by ring⟩
