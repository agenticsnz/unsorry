import Mathlib

theorem gself_pow_22_add_pow_fifteen (n : ℤ) : (n) ∣ (n^22 + n^15) := by
  exact ⟨n^21 + n^14, by ring⟩
