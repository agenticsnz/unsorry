import Mathlib

theorem gpow_diff_seven_pow_four (n : ℤ) : (n - 7) ∣ (n^4 - 2401) := by
  exact ⟨n^3 + 7*n^2 + 49*n + 343, by ring⟩
