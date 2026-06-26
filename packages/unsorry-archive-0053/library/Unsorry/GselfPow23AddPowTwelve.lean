import Mathlib

theorem gself_pow_23_add_pow_twelve (n : ℤ) : (n) ∣ (n^23 + n^12) := by
  exact ⟨n^22 + n^11, by ring⟩
