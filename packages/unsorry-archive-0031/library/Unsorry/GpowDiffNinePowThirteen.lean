import Mathlib

theorem gpow_diff_nine_pow_thirteen (n : ℤ) : (n - 9) ∣ (n^13 - 2541865828329) := by
  exact ⟨n^12 + 9*n^11 + 81*n^10 + 729*n^9 + 6561*n^8 + 59049*n^7 + 531441*n^6 + 4782969*n^5 + 43046721*n^4 + 387420489*n^3 + 3486784401*n^2 + 31381059609*n + 282429536481, by ring⟩
