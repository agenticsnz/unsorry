import Mathlib

theorem gself_pow_21_add_pow_six (n : ℤ) : (n) ∣ (n^21 + n^6) := by
  exact ⟨n^20 + n^5, by ring⟩
