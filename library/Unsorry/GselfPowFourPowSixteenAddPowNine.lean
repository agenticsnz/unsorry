import Mathlib

theorem gself_pow_four_pow_sixteen_add_pow_nine (n : ℤ) : (n^4) ∣ (n^16 + n^9) := by
  exact ⟨n^12 + n^5, by ring⟩
