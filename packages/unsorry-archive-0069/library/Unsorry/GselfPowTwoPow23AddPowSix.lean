import Mathlib

theorem gself_pow_two_pow_23_add_pow_six (n : ℤ) : (n^2) ∣ (n^23 + n^6) := by
  exact ⟨n^21 + n^4, by ring⟩
