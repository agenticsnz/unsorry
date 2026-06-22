import Mathlib

theorem gself_pow_nineteen_add_pow_ten (n : ℤ) : (n) ∣ (n^19 + n^10) := by
  exact ⟨n^18 + n^9, by ring⟩
