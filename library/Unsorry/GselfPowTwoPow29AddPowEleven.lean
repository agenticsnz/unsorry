import Mathlib

theorem gself_pow_two_pow_29_add_pow_eleven (n : ℤ) : (n^2) ∣ (n^29 + n^11) := by
  exact ⟨n^27 + n^9, by ring⟩
