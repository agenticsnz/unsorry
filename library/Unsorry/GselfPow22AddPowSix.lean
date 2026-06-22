import Mathlib

theorem gself_pow_22_add_pow_six (n : ℤ) : (n) ∣ (n^22 + n^6) := by
  exact ⟨n^21 + n^5, by ring⟩
