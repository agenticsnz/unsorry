import Mathlib

theorem gself_pow_23_add_pow_22 (n : ℤ) : (n) ∣ (n^23 + n^22) := by
  exact ⟨n^22 + n^21, by ring⟩
