import Mathlib

theorem gself_pow_nineteen_add_pow_nine (n : ℤ) : (n) ∣ (n^19 + n^9) := by
  exact ⟨n^18 + n^8, by ring⟩
