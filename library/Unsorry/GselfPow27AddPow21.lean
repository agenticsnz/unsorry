import Mathlib

theorem gself_pow_27_add_pow_21 (n : ℤ) : (n) ∣ (n^27 + n^21) := by
  exact ⟨n^26 + n^20, by ring⟩
