import Mathlib

theorem gself_pow_three_pow_23_add_pow_sixteen (n : ℤ) : (n^3) ∣ (n^23 + n^16) := by
  exact ⟨n^20 + n^13, by ring⟩
