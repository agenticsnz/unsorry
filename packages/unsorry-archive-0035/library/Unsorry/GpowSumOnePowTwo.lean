import Mathlib

theorem gpow_sum_one_pow_two (n : ℤ) : (n + 1) ∣ (n^2 - 1) := by
  exact ⟨n - 1, by ring⟩
