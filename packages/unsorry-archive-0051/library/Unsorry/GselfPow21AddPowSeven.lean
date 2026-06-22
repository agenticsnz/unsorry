import Mathlib

theorem gself_pow_21_add_pow_seven (n : ℤ) : (n) ∣ (n^21 + n^7) := by
  exact ⟨n^20 + n^6, by ring⟩
