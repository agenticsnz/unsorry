import Mathlib

theorem gpow_diff_three_pow_five (n : ℤ) : (n - 3) ∣ (n^5 - 243) := by
  exact ⟨n^4 + 3*n^3 + 9*n^2 + 27*n + 81, by ring⟩
