import Mathlib

theorem gself_pow_three_pow_26_add_pow_21 (n : ℤ) : (n^3) ∣ (n^26 + n^21) := by
  exact ⟨n^23 + n^18, by ring⟩
