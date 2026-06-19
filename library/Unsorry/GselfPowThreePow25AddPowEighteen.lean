import Mathlib

theorem gself_pow_three_pow_25_add_pow_eighteen (n : ℤ) : (n^3) ∣ (n^25 + n^18) := by
  exact ⟨n^22 + n^15, by ring⟩
