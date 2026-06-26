import Mathlib

theorem gpow_sum_five_pow_three (n : ℤ) : (n + 5) ∣ (n^3 + 125) := by
  exact ⟨n^2 - 5*n + 25, by ring⟩
