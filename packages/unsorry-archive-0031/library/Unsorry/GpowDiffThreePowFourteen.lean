import Mathlib

theorem gpow_diff_three_pow_fourteen (n : ℤ) : (n - 3) ∣ (n^14 - 4782969) := by
  exact ⟨n^13 + 3*n^12 + 9*n^11 + 27*n^10 + 81*n^9 + 243*n^8 + 729*n^7 + 2187*n^6 + 6561*n^5 + 19683*n^4 + 59049*n^3 + 177147*n^2 + 531441*n + 1594323, by ring⟩
