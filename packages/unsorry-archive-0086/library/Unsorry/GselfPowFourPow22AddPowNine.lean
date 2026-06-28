import Mathlib

theorem gself_pow_four_pow_22_add_pow_nine (n : ℤ) : (n^4) ∣ (n^22 + n^9) := by
  exact ⟨n^18 + n^5, by ring⟩
