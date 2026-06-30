import Mathlib

theorem gself_pow_three_pow_seventeen_add_pow_fifteen (n : ℤ) : (n^3) ∣ (n^17 + n^15) := by
  exact ⟨n^14 + n^12, by ring⟩
