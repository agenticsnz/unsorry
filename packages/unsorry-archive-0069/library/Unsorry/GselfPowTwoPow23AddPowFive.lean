import Mathlib

theorem gself_pow_two_pow_23_add_pow_five (n : ℤ) : (n^2) ∣ (n^23 + n^5) := by
  exact ⟨n^21 + n^3, by ring⟩
