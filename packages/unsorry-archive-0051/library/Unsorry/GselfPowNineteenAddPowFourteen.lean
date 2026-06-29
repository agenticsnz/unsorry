import Mathlib

theorem gself_pow_nineteen_add_pow_fourteen (n : ℤ) : (n) ∣ (n^19 + n^14) := by
  exact ⟨n^18 + n^13, by ring⟩
