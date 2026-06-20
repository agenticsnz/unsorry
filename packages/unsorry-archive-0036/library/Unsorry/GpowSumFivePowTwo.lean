import Mathlib

theorem gpow_sum_five_pow_two (n : ℤ) : (n + 5) ∣ (n^2 - 25) := by
  exact ⟨n - 5, by ring⟩
