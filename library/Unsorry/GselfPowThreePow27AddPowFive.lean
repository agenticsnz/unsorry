import Mathlib

theorem gself_pow_three_pow_27_add_pow_five (n : ℤ) : (n^3) ∣ (n^27 + n^5) := by
  exact ⟨n^24 + n^2, by ring⟩
