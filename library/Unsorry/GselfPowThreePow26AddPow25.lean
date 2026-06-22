import Mathlib

theorem gself_pow_three_pow_26_add_pow_25 (n : ℤ) : (n^3) ∣ (n^26 + n^25) := by
  exact ⟨n^23 + n^22, by ring⟩
