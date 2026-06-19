import Mathlib

theorem gself_pow_four_pow_sixteen_add_pow_twelve (n : ℤ) : (n^4) ∣ (n^16 + n^12) := by
  exact ⟨n^12 + n^8, by ring⟩
