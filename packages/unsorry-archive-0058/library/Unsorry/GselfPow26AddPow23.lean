import Mathlib

theorem gself_pow_26_add_pow_23 (n : ℤ) : (n) ∣ (n^26 + n^23) := by
  exact ⟨n^25 + n^22, by ring⟩
