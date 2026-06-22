import Mathlib

theorem gself_pow_three_pow_21_add_pow_eight (n : ℤ) : (n^3) ∣ (n^21 + n^8) := by
  exact ⟨n^18 + n^5, by ring⟩
