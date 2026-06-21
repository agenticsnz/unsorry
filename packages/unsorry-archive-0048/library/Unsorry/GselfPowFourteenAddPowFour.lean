import Mathlib

theorem gself_pow_fourteen_add_pow_four (n : ℤ) : (n) ∣ (n^14 + n^4) := by
  exact ⟨n^13 + n^3, by ring⟩
