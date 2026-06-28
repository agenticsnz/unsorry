import Mathlib

theorem gself_pow_three_pow_29_add_pow_26 (n : ℤ) : (n^3) ∣ (n^29 + n^26) := by
  exact ⟨n^26 + n^23, by ring⟩
