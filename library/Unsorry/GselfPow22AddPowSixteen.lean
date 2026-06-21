import Mathlib

theorem gself_pow_22_add_pow_sixteen (n : ℤ) : (n) ∣ (n^22 + n^16) := by
  exact ⟨n^21 + n^15, by ring⟩
