import Mathlib

theorem gself_pow_three_pow_eighteen_add_pow_three (n : ℤ) : (n^3) ∣ (n^18 + n^3) := by
  exact ⟨n^15 + 1, by ring⟩
