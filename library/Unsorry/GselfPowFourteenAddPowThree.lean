import Mathlib

theorem gself_pow_fourteen_add_pow_three (n : ℤ) : (n) ∣ (n^14 + n^3) := by
  exact ⟨n^13 + n^2, by ring⟩
