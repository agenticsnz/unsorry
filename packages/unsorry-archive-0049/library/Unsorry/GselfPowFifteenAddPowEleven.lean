import Mathlib

theorem gself_pow_fifteen_add_pow_eleven (n : ℤ) : (n) ∣ (n^15 + n^11) := by
  exact ⟨n^14 + n^10, by ring⟩
