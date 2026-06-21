import Mathlib

theorem gself_pow_23_add_pow_five (n : ℤ) : (n) ∣ (n^23 + n^5) := by
  exact ⟨n^22 + n^4, by ring⟩
