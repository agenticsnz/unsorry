import Mathlib

theorem gself_pow_22_add_pow_two (n : ℤ) : (n) ∣ (n^22 + n^2) := by
  exact ⟨n^21 + n, by ring⟩
