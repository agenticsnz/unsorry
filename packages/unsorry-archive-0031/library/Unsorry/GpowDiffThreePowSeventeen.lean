import Mathlib

theorem gpow_diff_three_pow_seventeen (n : ℤ) : (n - 3) ∣ (n^17 - 129140163) := by
  exact ⟨n^16 + 3*n^15 + 9*n^14 + 27*n^13 + 81*n^12 + 243*n^11 + 729*n^10 + 2187*n^9 + 6561*n^8 + 19683*n^7 + 59049*n^6 + 177147*n^5 + 531441*n^4 + 1594323*n^3 + 4782969*n^2 + 14348907*n + 43046721, by ring⟩
