import Mathlib

theorem gpow_diff_eleven_pow_five (n : ℤ) : (n - 11) ∣ (n^5 - 161051) := by
  exact ⟨n^4 + 11*n^3 + 121*n^2 + 1331*n + 14641, by ring⟩
