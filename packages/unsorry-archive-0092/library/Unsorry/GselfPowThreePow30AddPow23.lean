import Mathlib

theorem gself_pow_three_pow_30_add_pow_23 (n : ℤ) : (n^3) ∣ (n^30 + n^23) := by
  exact ⟨n^27 + n^20, by ring⟩
