import Mathlib

theorem gpow_diff_three_pow_nine (n : ℤ) : (n - 3) ∣ (n^9 - 19683) := by
  exact ⟨n^8 + 3*n^7 + 9*n^6 + 27*n^5 + 81*n^4 + 243*n^3 + 729*n^2 + 2187*n + 6561, by ring⟩
