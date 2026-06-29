import Mathlib

theorem gself_pow_three_pow_eight_add_pow_four (n : ℤ) : (n^3) ∣ (n^8 + n^4) := by
  exact ⟨n^5 + n, by ring⟩
