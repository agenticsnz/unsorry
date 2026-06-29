import Mathlib

theorem gpow_sum_eleven_pow_eleven (n : ℤ) : (n + 11) ∣ (n^11 + 285311670611) := by
  exact ⟨n^10 - 11*n^9 + 121*n^8 - 1331*n^7 + 14641*n^6 - 161051*n^5 + 1771561*n^4 - 19487171*n^3 + 214358881*n^2 - 2357947691*n + 25937424601, by ring⟩
