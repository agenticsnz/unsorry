import Mathlib

theorem gself_pow_three_pow_30_add_pow_six (n : ℤ) : (n^3) ∣ (n^30 + n^6) := by
  exact ⟨n^27 + n^3, by ring⟩
