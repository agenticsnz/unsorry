import Mathlib

theorem gself_pow_three_pow_21_add_pow_six (n : ℤ) : (n^3) ∣ (n^21 + n^6) := by
  exact ⟨n^18 + n^3, by ring⟩
