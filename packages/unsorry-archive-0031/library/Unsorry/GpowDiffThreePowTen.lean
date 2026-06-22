import Mathlib

theorem gpow_diff_three_pow_ten (n : ℤ) : (n - 3) ∣ (n^10 - 59049) := by
  exact ⟨n^9 + 3*n^8 + 9*n^7 + 27*n^6 + 81*n^5 + 243*n^4 + 729*n^3 + 2187*n^2 + 6561*n + 19683, by ring⟩
