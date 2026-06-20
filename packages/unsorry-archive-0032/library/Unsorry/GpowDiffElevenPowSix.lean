import Mathlib

theorem gpow_diff_eleven_pow_six (n : ℤ) : (n - 11) ∣ (n^6 - 1771561) := by
  exact ⟨n^5 + 11*n^4 + 121*n^3 + 1331*n^2 + 14641*n + 161051, by ring⟩
