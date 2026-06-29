import Mathlib

theorem gself_pow_three_pow_30_add_pow_eighteen (n : ℤ) : (n^3) ∣ (n^30 + n^18) := by
  exact ⟨n^27 + n^15, by ring⟩
