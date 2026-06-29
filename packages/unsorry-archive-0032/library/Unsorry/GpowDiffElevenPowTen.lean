import Mathlib

theorem gpow_diff_eleven_pow_ten (n : ℤ) : (n - 11) ∣ (n^10 - 25937424601) := by
  exact ⟨n^9 + 11*n^8 + 121*n^7 + 1331*n^6 + 14641*n^5 + 161051*n^4 + 1771561*n^3 + 19487171*n^2 + 214358881*n + 2357947691, by ring⟩
