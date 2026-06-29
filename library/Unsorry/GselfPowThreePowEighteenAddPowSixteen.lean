import Mathlib

theorem gself_pow_three_pow_eighteen_add_pow_sixteen (n : ℤ) : (n^3) ∣ (n^18 + n^16) := by
  exact ⟨n^15 + n^13, by ring⟩
