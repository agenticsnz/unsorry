import Mathlib

theorem gself_pow_fourteen_add_pow_nine (n : ℤ) : (n) ∣ (n^14 + n^9) := by
  exact ⟨n^13 + n^8, by ring⟩
