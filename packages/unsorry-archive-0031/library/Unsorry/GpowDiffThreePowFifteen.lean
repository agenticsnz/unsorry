import Mathlib

theorem gpow_diff_three_pow_fifteen (n : ℤ) : (n - 3) ∣ (n^15 - 14348907) := by
  exact ⟨n^14 + 3*n^13 + 9*n^12 + 27*n^11 + 81*n^10 + 243*n^9 + 729*n^8 + 2187*n^7 + 6561*n^6 + 19683*n^5 + 59049*n^4 + 177147*n^3 + 531441*n^2 + 1594323*n + 4782969, by ring⟩
