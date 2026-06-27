import Mathlib

theorem gself_pow_two_pow_25_add_pow_eighteen (n : ℤ) : (n^2) ∣ (n^25 + n^18) := by
  exact ⟨n^23 + n^16, by ring⟩
