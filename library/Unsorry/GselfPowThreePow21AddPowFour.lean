import Mathlib

theorem gself_pow_three_pow_21_add_pow_four (n : ℤ) : (n^3) ∣ (n^21 + n^4) := by
  exact ⟨n^18 + n, by ring⟩
