import Mathlib

theorem gself_pow_four_pow_22_add_pow_four (n : ℤ) : (n^4) ∣ (n^22 + n^4) := by
  exact ⟨n^18 + 1, by ring⟩
