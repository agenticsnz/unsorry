import Mathlib

theorem gself_pow_three_pow_eighteen_add_pow_fourteen (n : ℤ) : (n^3) ∣ (n^18 + n^14) := by
  exact ⟨n^15 + n^11, by ring⟩
