import Mathlib

theorem gself_pow_four_pow_22_add_pow_eight (n : ℤ) : (n^4) ∣ (n^22 + n^8) := by
  exact ⟨n^18 + n^4, by ring⟩
