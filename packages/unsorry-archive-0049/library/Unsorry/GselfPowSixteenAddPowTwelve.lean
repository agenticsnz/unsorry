import Mathlib

theorem gself_pow_sixteen_add_pow_twelve (n : ℤ) : (n) ∣ (n^16 + n^12) := by
  exact ⟨n^15 + n^11, by ring⟩
