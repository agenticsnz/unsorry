import Mathlib

theorem gself_pow_21_add_pow_nine (n : ℤ) : (n) ∣ (n^21 + n^9) := by
  exact ⟨n^20 + n^8, by ring⟩
