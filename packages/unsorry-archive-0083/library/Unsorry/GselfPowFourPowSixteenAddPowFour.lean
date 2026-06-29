import Mathlib

theorem gself_pow_four_pow_sixteen_add_pow_four (n : ℤ) : (n^4) ∣ (n^16 + n^4) := by
  exact ⟨n^12 + 1, by ring⟩
