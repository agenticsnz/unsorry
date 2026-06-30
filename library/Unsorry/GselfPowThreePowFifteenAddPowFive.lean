import Mathlib

theorem gself_pow_three_pow_fifteen_add_pow_five (n : ℤ) : (n^3) ∣ (n^15 + n^5) := by
  exact ⟨n^12 + n^2, by ring⟩
