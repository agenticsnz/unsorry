import Mathlib

theorem gself_pow_eight_add_pow_two (n : ℤ) : (n) ∣ (n^8 + n^2) := by
  exact ⟨n^7 + n, by ring⟩
