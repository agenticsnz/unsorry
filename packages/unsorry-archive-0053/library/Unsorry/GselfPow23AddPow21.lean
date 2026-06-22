import Mathlib

theorem gself_pow_23_add_pow_21 (n : ℤ) : (n) ∣ (n^23 + n^21) := by
  exact ⟨n^22 + n^20, by ring⟩
