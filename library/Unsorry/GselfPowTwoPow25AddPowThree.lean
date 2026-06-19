import Mathlib

theorem gself_pow_two_pow_25_add_pow_three (n : ℤ) : (n^2) ∣ (n^25 + n^3) := by
  exact ⟨n^23 + n, by ring⟩
