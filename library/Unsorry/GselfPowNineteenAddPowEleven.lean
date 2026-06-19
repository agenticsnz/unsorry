import Mathlib

theorem gself_pow_nineteen_add_pow_eleven (n : ℤ) : (n) ∣ (n^19 + n^11) := by
  exact ⟨n^18 + n^10, by ring⟩
