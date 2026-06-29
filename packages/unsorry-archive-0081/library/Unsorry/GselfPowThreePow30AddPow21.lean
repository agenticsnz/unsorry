import Mathlib

theorem gself_pow_three_pow_30_add_pow_21 (n : ℤ) : (n^3) ∣ (n^30 + n^21) := by
  exact ⟨n^27 + n^18, by ring⟩
