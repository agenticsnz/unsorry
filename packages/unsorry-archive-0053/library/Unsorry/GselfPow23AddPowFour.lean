import Mathlib

theorem gself_pow_23_add_pow_four (n : ℤ) : (n) ∣ (n^23 + n^4) := by
  exact ⟨n^22 + n^3, by ring⟩
