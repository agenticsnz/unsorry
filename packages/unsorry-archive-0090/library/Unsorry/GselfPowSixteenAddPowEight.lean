import Mathlib

theorem gself_pow_sixteen_add_pow_eight (n : ℤ) : (n) ∣ (n^16 + n^8) := by
  exact ⟨n^15 + n^7, by ring⟩
