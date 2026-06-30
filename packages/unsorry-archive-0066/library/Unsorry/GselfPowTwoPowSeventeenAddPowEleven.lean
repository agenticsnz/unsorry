import Mathlib

theorem gself_pow_two_pow_seventeen_add_pow_eleven (n : ℤ) : (n^2) ∣ (n^17 + n^11) := by
  exact ⟨n^15 + n^9, by ring⟩
