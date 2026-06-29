import Mathlib

theorem gself_pow_nineteen_add_pow_sixteen (n : ℤ) : (n) ∣ (n^19 + n^16) := by
  exact ⟨n^18 + n^15, by ring⟩
