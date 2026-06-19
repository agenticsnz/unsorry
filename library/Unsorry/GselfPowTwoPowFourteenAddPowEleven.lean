import Mathlib

theorem gself_pow_two_pow_fourteen_add_pow_eleven (n : ℤ) : (n^2) ∣ (n^14 + n^11) := by
  exact ⟨n^12 + n^9, by ring⟩
