import Mathlib

theorem gself_pow_fourteen_add_pow_eleven (n : ℤ) : (n) ∣ (n^14 + n^11) := by
  exact ⟨n^13 + n^10, by ring⟩
