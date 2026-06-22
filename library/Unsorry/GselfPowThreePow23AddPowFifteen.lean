import Mathlib

theorem gself_pow_three_pow_23_add_pow_fifteen (n : ℤ) : (n^3) ∣ (n^23 + n^15) := by
  exact ⟨n^20 + n^12, by ring⟩
