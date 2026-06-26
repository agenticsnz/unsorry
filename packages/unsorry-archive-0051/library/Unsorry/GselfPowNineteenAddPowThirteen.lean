import Mathlib

theorem gself_pow_nineteen_add_pow_thirteen (n : ℤ) : (n) ∣ (n^19 + n^13) := by
  exact ⟨n^18 + n^12, by ring⟩
