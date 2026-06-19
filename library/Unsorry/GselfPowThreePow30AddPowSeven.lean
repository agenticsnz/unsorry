import Mathlib

theorem gself_pow_three_pow_30_add_pow_seven (n : ℤ) : (n^3) ∣ (n^30 + n^7) := by
  exact ⟨n^27 + n^4, by ring⟩
