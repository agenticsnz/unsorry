import Mathlib

theorem gself_pow_sixteen_add_pow_five (n : ℤ) : (n) ∣ (n^16 + n^5) := by
  exact ⟨n^15 + n^4, by ring⟩
