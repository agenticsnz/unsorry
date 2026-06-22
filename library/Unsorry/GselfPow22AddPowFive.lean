import Mathlib

theorem gself_pow_22_add_pow_five (n : ℤ) : (n) ∣ (n^22 + n^5) := by
  exact ⟨n^21 + n^4, by ring⟩
