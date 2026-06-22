import Mathlib

theorem gself_pow_seventeen_add_pow_nine (n : ℤ) : (n) ∣ (n^17 + n^9) := by
  exact ⟨n^16 + n^8, by ring⟩
