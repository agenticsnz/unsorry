import Mathlib

theorem gself_pow_two_pow_three_add_pow_two (n : ℤ) : (n^2) ∣ (n^3 + n^2) := by
  exact ⟨n + 1, by ring⟩
