import Mathlib

theorem gself_pow_three_pow_21_add_pow_five (n : ℤ) : (n^3) ∣ (n^21 + n^5) := by
  exact ⟨n^18 + n^2, by ring⟩
