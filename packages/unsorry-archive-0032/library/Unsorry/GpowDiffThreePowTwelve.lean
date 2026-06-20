import Mathlib

theorem gpow_diff_three_pow_twelve (n : ℤ) : (n - 3) ∣ (n^12 - 531441) := by
  exact ⟨n^11 + 3*n^10 + 9*n^9 + 27*n^8 + 81*n^7 + 243*n^6 + 729*n^5 + 2187*n^4 + 6561*n^3 + 19683*n^2 + 59049*n + 177147, by ring⟩
