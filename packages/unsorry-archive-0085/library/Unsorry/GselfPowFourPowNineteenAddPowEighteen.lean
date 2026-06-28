import Mathlib

theorem gself_pow_four_pow_nineteen_add_pow_eighteen (n : ℤ) : (n^4) ∣ (n^19 + n^18) := by
  exact ⟨n^15 + n^14, by ring⟩
