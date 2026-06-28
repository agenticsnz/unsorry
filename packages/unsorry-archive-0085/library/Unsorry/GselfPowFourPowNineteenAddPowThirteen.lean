import Mathlib

theorem gself_pow_four_pow_nineteen_add_pow_thirteen (n : ℤ) : (n^4) ∣ (n^19 + n^13) := by
  exact ⟨n^15 + n^9, by ring⟩
