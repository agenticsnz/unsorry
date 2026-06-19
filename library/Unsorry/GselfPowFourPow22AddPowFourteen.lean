import Mathlib

theorem gself_pow_four_pow_22_add_pow_fourteen (n : ℤ) : (n^4) ∣ (n^22 + n^14) := by
  exact ⟨n^18 + n^10, by ring⟩
