import Mathlib

theorem gpow_diff_nine_pow_twelve (n : ℤ) : (n - 9) ∣ (n^12 - 282429536481) := by
  exact ⟨n^11 + 9*n^10 + 81*n^9 + 729*n^8 + 6561*n^7 + 59049*n^6 + 531441*n^5 + 4782969*n^4 + 43046721*n^3 + 387420489*n^2 + 3486784401*n + 31381059609, by ring⟩
