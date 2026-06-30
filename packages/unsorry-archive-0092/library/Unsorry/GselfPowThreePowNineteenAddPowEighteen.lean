import Mathlib

theorem gself_pow_three_pow_nineteen_add_pow_eighteen (n : ℤ) : (n^3) ∣ (n^19 + n^18) := by
  exact ⟨n^16 + n^15, by ring⟩
