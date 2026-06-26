import Mathlib

theorem gself_pow_two_pow_29_add_pow_three (n : ℤ) : (n^2) ∣ (n^29 + n^3) := by
  exact ⟨n^27 + n, by ring⟩
