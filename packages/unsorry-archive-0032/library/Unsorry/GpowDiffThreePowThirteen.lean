import Mathlib

theorem gpow_diff_three_pow_thirteen (n : ℤ) : (n - 3) ∣ (n^13 - 1594323) := by
  exact ⟨n^12 + 3*n^11 + 9*n^10 + 27*n^9 + 81*n^8 + 243*n^7 + 729*n^6 + 2187*n^5 + 6561*n^4 + 19683*n^3 + 59049*n^2 + 177147*n + 531441, by ring⟩
