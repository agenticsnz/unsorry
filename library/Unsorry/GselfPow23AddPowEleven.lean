import Mathlib

theorem gself_pow_23_add_pow_eleven (n : ℤ) : (n) ∣ (n^23 + n^11) := by
  exact ⟨n^22 + n^10, by ring⟩
