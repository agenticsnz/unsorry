import Mathlib

theorem gself_pow_three_pow_25_add_pow_four (n : ℤ) : (n^3) ∣ (n^25 + n^4) := by
  exact ⟨n^22 + n, by ring⟩
