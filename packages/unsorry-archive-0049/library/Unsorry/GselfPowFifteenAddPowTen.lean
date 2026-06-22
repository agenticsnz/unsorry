import Mathlib

theorem gself_pow_fifteen_add_pow_ten (n : ℤ) : (n) ∣ (n^15 + n^10) := by
  exact ⟨n^14 + n^9, by ring⟩
