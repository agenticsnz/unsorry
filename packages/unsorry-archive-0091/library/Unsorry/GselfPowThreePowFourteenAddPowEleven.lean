import Mathlib

theorem gself_pow_three_pow_fourteen_add_pow_eleven (n : ℤ) : (n^3) ∣ (n^14 + n^11) := by
  exact ⟨n^11 + n^8, by ring⟩
