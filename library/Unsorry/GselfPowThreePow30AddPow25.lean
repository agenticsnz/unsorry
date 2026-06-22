import Mathlib

theorem gself_pow_three_pow_30_add_pow_25 (n : ℤ) : (n^3) ∣ (n^30 + n^25) := by
  exact ⟨n^27 + n^22, by ring⟩
