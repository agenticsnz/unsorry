import Mathlib

theorem gself_pow_three_pow_fourteen_add_pow_ten (n : ℤ) : (n^3) ∣ (n^14 + n^10) := by
  exact ⟨n^11 + n^7, by ring⟩
