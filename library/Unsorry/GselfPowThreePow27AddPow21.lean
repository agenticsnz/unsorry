import Mathlib

theorem gself_pow_three_pow_27_add_pow_21 (n : ℤ) : (n^3) ∣ (n^27 + n^21) := by
  exact ⟨n^24 + n^18, by ring⟩
