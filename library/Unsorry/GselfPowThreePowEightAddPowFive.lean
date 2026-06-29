import Mathlib

theorem gself_pow_three_pow_eight_add_pow_five (n : ℤ) : (n^3) ∣ (n^8 + n^5) := by
  exact ⟨n^5 + n^2, by ring⟩
