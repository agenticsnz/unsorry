import Mathlib

theorem gself_pow_nineteen_add_pow_seven (n : ℤ) : (n) ∣ (n^19 + n^7) := by
  exact ⟨n^18 + n^6, by ring⟩
