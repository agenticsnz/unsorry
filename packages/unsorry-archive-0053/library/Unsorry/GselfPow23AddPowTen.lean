import Mathlib

theorem gself_pow_23_add_pow_ten (n : ℤ) : (n) ∣ (n^23 + n^10) := by
  exact ⟨n^22 + n^9, by ring⟩
