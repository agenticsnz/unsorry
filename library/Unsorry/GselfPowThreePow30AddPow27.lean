import Mathlib

theorem gself_pow_three_pow_30_add_pow_27 (n : ℤ) : (n^3) ∣ (n^30 + n^27) := by
  exact ⟨n^27 + n^24, by ring⟩
