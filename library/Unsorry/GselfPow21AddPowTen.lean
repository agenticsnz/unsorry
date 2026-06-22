import Mathlib

theorem gself_pow_21_add_pow_ten (n : ℤ) : (n) ∣ (n^21 + n^10) := by
  exact ⟨n^20 + n^9, by ring⟩
