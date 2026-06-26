import Mathlib

theorem gself_pow_three_pow_29_add_pow_22 (n : ℤ) : (n^3) ∣ (n^29 + n^22) := by
  exact ⟨n^26 + n^19, by ring⟩
