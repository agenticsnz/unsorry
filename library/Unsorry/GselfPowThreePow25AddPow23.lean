import Mathlib

theorem gself_pow_three_pow_25_add_pow_23 (n : ℤ) : (n^3) ∣ (n^25 + n^23) := by
  exact ⟨n^22 + n^20, by ring⟩
