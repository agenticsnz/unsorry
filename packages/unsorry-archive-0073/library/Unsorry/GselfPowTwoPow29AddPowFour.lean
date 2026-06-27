import Mathlib

theorem gself_pow_two_pow_29_add_pow_four (n : ℤ) : (n^2) ∣ (n^29 + n^4) := by
  exact ⟨n^27 + n^2, by ring⟩
