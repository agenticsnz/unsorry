import Mathlib

theorem gpow_diff_three_pow_eleven (n : ℤ) : (n - 3) ∣ (n^11 - 177147) := by
  exact ⟨n^10 + 3*n^9 + 9*n^8 + 27*n^7 + 81*n^6 + 243*n^5 + 729*n^4 + 2187*n^3 + 6561*n^2 + 19683*n + 59049, by ring⟩
