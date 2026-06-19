import Mathlib

theorem gself_pow_nineteen_add_pow_four (n : ℤ) : (n) ∣ (n^19 + n^4) := by
  exact ⟨n^18 + n^3, by ring⟩
