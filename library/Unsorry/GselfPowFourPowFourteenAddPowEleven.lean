import Mathlib

theorem gself_pow_four_pow_fourteen_add_pow_eleven (n : ℤ) : (n^4) ∣ (n^14 + n^11) := by
  exact ⟨n^10 + n^7, by ring⟩
