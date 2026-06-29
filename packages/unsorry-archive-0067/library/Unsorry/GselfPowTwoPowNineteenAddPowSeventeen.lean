import Mathlib

theorem gself_pow_two_pow_nineteen_add_pow_seventeen (n : ℤ) : (n^2) ∣ (n^19 + n^17) := by
  exact ⟨n^17 + n^15, by ring⟩
