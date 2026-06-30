import Mathlib

theorem gself_pow_three_pow_fourteen_add_pow_nine (n : ℤ) : (n^3) ∣ (n^14 + n^9) := by
  exact ⟨n^11 + n^6, by ring⟩
