import Mathlib

theorem gself_pow_nineteen_add_pow_eight (n : ℤ) : (n) ∣ (n^19 + n^8) := by
  exact ⟨n^18 + n^7, by ring⟩
