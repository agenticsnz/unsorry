import Mathlib

theorem gpow_diff_nine_pow_four (n : ℤ) : (n - 9) ∣ (n^4 - 6561) := by
  exact ⟨n^3 + 9*n^2 + 81*n + 729, by ring⟩
