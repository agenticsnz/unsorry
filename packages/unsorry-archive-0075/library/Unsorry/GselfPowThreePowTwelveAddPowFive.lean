import Mathlib

theorem gself_pow_three_pow_twelve_add_pow_five (n : ℤ) : (n^3) ∣ (n^12 + n^5) := by
  exact ⟨n^9 + n^2, by ring⟩
