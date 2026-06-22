import Mathlib

theorem gself_pow_nineteen_add_pow_five (n : ℤ) : (n) ∣ (n^19 + n^5) := by
  exact ⟨n^18 + n^4, by ring⟩
