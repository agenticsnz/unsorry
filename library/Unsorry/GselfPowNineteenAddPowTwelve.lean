import Mathlib

theorem gself_pow_nineteen_add_pow_twelve (n : ℤ) : (n) ∣ (n^19 + n^12) := by
  exact ⟨n^18 + n^11, by ring⟩
