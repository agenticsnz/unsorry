import Mathlib

theorem gself_pow_three_pow_29_add_pow_eighteen (n : ℤ) : (n^3) ∣ (n^29 + n^18) := by
  exact ⟨n^26 + n^15, by ring⟩
