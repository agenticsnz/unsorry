import Mathlib

theorem gself_pow_three_pow_25_add_pow_21 (n : ℤ) : (n^3) ∣ (n^25 + n^21) := by
  exact ⟨n^22 + n^18, by ring⟩
