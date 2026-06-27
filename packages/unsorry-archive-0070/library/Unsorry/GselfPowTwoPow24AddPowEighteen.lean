import Mathlib

theorem gself_pow_two_pow_24_add_pow_eighteen (n : ℤ) : (n^2) ∣ (n^24 + n^18) := by
  exact ⟨n^22 + n^16, by ring⟩
