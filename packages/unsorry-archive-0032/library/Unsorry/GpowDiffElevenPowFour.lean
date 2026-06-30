import Mathlib

theorem gpow_diff_eleven_pow_four (n : ℤ) : (n - 11) ∣ (n^4 - 14641) := by
  exact ⟨n^3 + 11*n^2 + 121*n + 1331, by ring⟩
