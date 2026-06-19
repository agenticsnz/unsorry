import Mathlib

theorem gself_pow_fourteen_add_pow_ten (n : ℤ) : (n) ∣ (n^14 + n^10) := by
  exact ⟨n^13 + n^9, by ring⟩
