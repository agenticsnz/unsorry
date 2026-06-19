import Mathlib

theorem gself_pow_sixteen_add_pow_eleven (n : ℤ) : (n) ∣ (n^16 + n^11) := by
  exact ⟨n^15 + n^10, by ring⟩
