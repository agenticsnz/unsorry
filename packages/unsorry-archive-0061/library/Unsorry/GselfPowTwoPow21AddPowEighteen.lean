import Mathlib

theorem gself_pow_two_pow_21_add_pow_eighteen (n : ℤ) : (n^2) ∣ (n^21 + n^18) := by
  exact ⟨n^19 + n^16, by ring⟩
