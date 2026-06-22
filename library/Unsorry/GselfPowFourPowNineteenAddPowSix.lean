import Mathlib

theorem gself_pow_four_pow_nineteen_add_pow_six (n : ℤ) : (n^4) ∣ (n^19 + n^6) := by
  exact ⟨n^15 + n^2, by ring⟩
