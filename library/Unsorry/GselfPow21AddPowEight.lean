import Mathlib

theorem gself_pow_21_add_pow_eight (n : ℤ) : (n) ∣ (n^21 + n^8) := by
  exact ⟨n^20 + n^7, by ring⟩
