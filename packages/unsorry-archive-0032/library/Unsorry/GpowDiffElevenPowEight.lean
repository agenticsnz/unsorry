import Mathlib

theorem gpow_diff_eleven_pow_eight (n : ℤ) : (n - 11) ∣ (n^8 - 214358881) := by
  exact ⟨n^7 + 11*n^6 + 121*n^5 + 1331*n^4 + 14641*n^3 + 161051*n^2 + 1771561*n + 19487171, by ring⟩
