import Mathlib

theorem gself_pow_two_pow_nineteen_add_pow_six (n : ℤ) : (n^2) ∣ (n^19 + n^6) := by
  exact ⟨n^17 + n^4, by ring⟩
