import Mathlib

theorem gself_pow_three_pow_23_add_pow_twelve (n : ℤ) : (n^3) ∣ (n^23 + n^12) := by
  exact ⟨n^20 + n^9, by ring⟩
