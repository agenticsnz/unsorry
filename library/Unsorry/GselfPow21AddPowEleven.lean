import Mathlib

theorem gself_pow_21_add_pow_eleven (n : ℤ) : (n) ∣ (n^21 + n^11) := by
  exact ⟨n^20 + n^10, by ring⟩
