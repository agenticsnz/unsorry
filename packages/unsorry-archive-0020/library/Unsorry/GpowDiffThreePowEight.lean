import Mathlib

theorem gpow_diff_three_pow_eight (n : ℤ) : (n - 3) ∣ (n^8 - 6561) := by
  exact ⟨n^7 + 3*n^6 + 9*n^5 + 27*n^4 + 81*n^3 + 243*n^2 + 729*n + 2187, by ring⟩
