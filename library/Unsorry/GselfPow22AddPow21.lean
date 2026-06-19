import Mathlib

theorem gself_pow_22_add_pow_21 (n : ℤ) : (n) ∣ (n^22 + n^21) := by
  exact ⟨n^21 + n^20, by ring⟩
