import Mathlib

theorem gself_pow_21_add_pow_twelve (n : ℤ) : (n) ∣ (n^21 + n^12) := by
  exact ⟨n^20 + n^11, by ring⟩
