import Mathlib

theorem gself_pow_four_pow_sixteen_add_pow_eleven (n : ℤ) : (n^4) ∣ (n^16 + n^11) := by
  exact ⟨n^12 + n^7, by ring⟩
