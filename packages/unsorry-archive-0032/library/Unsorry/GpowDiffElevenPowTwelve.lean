import Mathlib

theorem gpow_diff_eleven_pow_twelve (n : ℤ) : (n - 11) ∣ (n^12 - 3138428376721) := by
  exact ⟨n^11 + 11*n^10 + 121*n^9 + 1331*n^8 + 14641*n^7 + 161051*n^6 + 1771561*n^5 + 19487171*n^4 + 214358881*n^3 + 2357947691*n^2 + 25937424601*n + 285311670611, by ring⟩
