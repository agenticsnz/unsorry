import Mathlib

theorem gself_pow_nineteen_add_pow_eighteen (n : ℤ) : (n) ∣ (n^19 + n^18) := by
  exact ⟨n^18 + n^17, by ring⟩
