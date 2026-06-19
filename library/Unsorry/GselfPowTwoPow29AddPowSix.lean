import Mathlib

theorem gself_pow_two_pow_29_add_pow_six (n : ℤ) : (n^2) ∣ (n^29 + n^6) := by
  exact ⟨n^27 + n^4, by ring⟩
