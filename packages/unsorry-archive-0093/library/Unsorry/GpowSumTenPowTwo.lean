import Mathlib

theorem gpow_sum_ten_pow_two (n : ℤ) : (n + 10) ∣ (n^2 - 100) := by
  exact ⟨n - 10, by ring⟩
