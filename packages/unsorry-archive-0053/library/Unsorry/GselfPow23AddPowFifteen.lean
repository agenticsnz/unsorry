import Mathlib

theorem gself_pow_23_add_pow_fifteen (n : ℤ) : (n) ∣ (n^23 + n^15) := by
  exact ⟨n^22 + n^14, by ring⟩
