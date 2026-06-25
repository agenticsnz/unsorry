import Mathlib

theorem gself_pow_26_add_pow_22 (n : ℤ) : (n) ∣ (n^26 + n^22) := by
  exact ⟨n^25 + n^21, by ring⟩
