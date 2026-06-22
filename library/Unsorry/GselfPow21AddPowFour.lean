import Mathlib

theorem gself_pow_21_add_pow_four (n : ℤ) : (n) ∣ (n^21 + n^4) := by
  exact ⟨n^20 + n^3, by ring⟩
