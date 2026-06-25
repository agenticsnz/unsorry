import Mathlib

theorem gself_pow_three_pow_29_add_pow_21 (n : ℤ) : (n^3) ∣ (n^29 + n^21) := by
  exact ⟨n^26 + n^18, by ring⟩
