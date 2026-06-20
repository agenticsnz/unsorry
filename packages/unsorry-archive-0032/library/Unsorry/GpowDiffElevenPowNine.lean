import Mathlib

theorem gpow_diff_eleven_pow_nine (n : ℤ) : (n - 11) ∣ (n^9 - 2357947691) := by
  exact ⟨n^8 + 11*n^7 + 121*n^6 + 1331*n^5 + 14641*n^4 + 161051*n^3 + 1771561*n^2 + 19487171*n + 214358881, by ring⟩
