import Mathlib

theorem gself_pow_three_pow_30_add_pow_ten (n : ℤ) : (n^3) ∣ (n^30 + n^10) := by
  exact ⟨n^27 + n^7, by ring⟩
