import Mathlib

theorem gself_pow_fifteen_add_pow_nine (n : ℤ) : (n) ∣ (n^15 + n^9) := by
  exact ⟨n^14 + n^8, by ring⟩
