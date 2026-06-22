import Mathlib

theorem gself_pow_23_add_pow_eight (n : ℤ) : (n) ∣ (n^23 + n^8) := by
  exact ⟨n^22 + n^7, by ring⟩
