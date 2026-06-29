import Mathlib

theorem gpow_sum_eleven_pow_seven (n : ℤ) : (n + 11) ∣ (n^7 + 19487171) := by
  exact ⟨n^6 - 11*n^5 + 121*n^4 - 1331*n^3 + 14641*n^2 - 161051*n + 1771561, by ring⟩
