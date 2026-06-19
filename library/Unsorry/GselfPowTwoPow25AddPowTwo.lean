import Mathlib

theorem gself_pow_two_pow_25_add_pow_two (n : ℤ) : (n^2) ∣ (n^25 + n^2) := by
  exact ⟨n^23 + 1, by ring⟩
