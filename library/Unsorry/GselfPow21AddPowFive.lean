import Mathlib

theorem gself_pow_21_add_pow_five (n : ℤ) : (n) ∣ (n^21 + n^5) := by
  exact ⟨n^20 + n^4, by ring⟩
