import Mathlib

theorem gself_pow_two_pow_nineteen_add_pow_eighteen (n : ℤ) : (n^2) ∣ (n^19 + n^18) := by
  exact ⟨n^17 + n^16, by ring⟩
