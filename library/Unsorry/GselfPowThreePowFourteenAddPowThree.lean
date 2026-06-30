import Mathlib

theorem gself_pow_three_pow_fourteen_add_pow_three (n : ℤ) : (n^3) ∣ (n^14 + n^3) := by
  exact ⟨n^11 + 1, by ring⟩
