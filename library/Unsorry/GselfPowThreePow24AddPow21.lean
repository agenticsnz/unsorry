import Mathlib

theorem gself_pow_three_pow_24_add_pow_21 (n : ℤ) : (n^3) ∣ (n^24 + n^21) := by
  exact ⟨n^21 + n^18, by ring⟩
