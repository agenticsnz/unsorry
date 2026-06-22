import Mathlib

theorem gself_pow_three_add_pow_two (n : ℤ) : (n) ∣ (n^3 + n^2) := by
  exact ⟨n^2 + n, by ring⟩
