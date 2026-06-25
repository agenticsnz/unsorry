import Mathlib

theorem gself_pow_28_add_pow_eleven (n : ℤ) : (n) ∣ (n^28 + n^11) := by
  exact ⟨n^27 + n^10, by ring⟩
