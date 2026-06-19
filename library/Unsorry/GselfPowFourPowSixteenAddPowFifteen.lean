import Mathlib

theorem gself_pow_four_pow_sixteen_add_pow_fifteen (n : ℤ) : (n^4) ∣ (n^16 + n^15) := by
  exact ⟨n^12 + n^11, by ring⟩
