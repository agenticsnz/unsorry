import Mathlib

theorem gself_pow_nineteen_add_pow_fifteen (n : ℤ) : (n) ∣ (n^19 + n^15) := by
  exact ⟨n^18 + n^14, by ring⟩
