import Mathlib

theorem gself_pow_four_pow_nineteen_add_pow_seventeen (n : ℤ) : (n^4) ∣ (n^19 + n^17) := by
  exact ⟨n^15 + n^13, by ring⟩
