import Mathlib

theorem gpow_diff_three_pow_sixteen (n : ℤ) : (n - 3) ∣ (n^16 - 43046721) := by
  exact ⟨n^15 + 3*n^14 + 9*n^13 + 27*n^12 + 81*n^11 + 243*n^10 + 729*n^9 + 2187*n^8 + 6561*n^7 + 19683*n^6 + 59049*n^5 + 177147*n^4 + 531441*n^3 + 1594323*n^2 + 4782969*n + 14348907, by ring⟩
