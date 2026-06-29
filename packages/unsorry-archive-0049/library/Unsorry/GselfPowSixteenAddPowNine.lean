import Mathlib

theorem gself_pow_sixteen_add_pow_nine (n : ℤ) : (n) ∣ (n^16 + n^9) := by
  exact ⟨n^15 + n^8, by ring⟩
