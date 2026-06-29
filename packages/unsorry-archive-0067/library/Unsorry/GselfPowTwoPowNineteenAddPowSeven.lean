import Mathlib

theorem gself_pow_two_pow_nineteen_add_pow_seven (n : ℤ) : (n^2) ∣ (n^19 + n^7) := by
  exact ⟨n^17 + n^5, by ring⟩
