import Mathlib

theorem gself_pow_four_pow_21_add_pow_five (n : ℤ) : (n^4) ∣ (n^21 + n^5) := by
  exact ⟨n^17 + n, by ring⟩
