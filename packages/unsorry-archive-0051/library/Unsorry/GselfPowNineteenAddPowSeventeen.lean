import Mathlib

theorem gself_pow_nineteen_add_pow_seventeen (n : ℤ) : (n) ∣ (n^19 + n^17) := by
  exact ⟨n^18 + n^16, by ring⟩
