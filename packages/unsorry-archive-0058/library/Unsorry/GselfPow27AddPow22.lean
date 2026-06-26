import Mathlib

theorem gself_pow_27_add_pow_22 (n : ℤ) : (n) ∣ (n^27 + n^22) := by
  exact ⟨n^26 + n^21, by ring⟩
