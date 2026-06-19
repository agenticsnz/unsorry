import Mathlib

theorem gself_pow_two_pow_29_add_pow_25 (n : ℤ) : (n^2) ∣ (n^29 + n^25) := by
  exact ⟨n^27 + n^23, by ring⟩
