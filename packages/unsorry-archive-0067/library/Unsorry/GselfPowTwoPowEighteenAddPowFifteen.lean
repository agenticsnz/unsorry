import Mathlib

theorem gself_pow_two_pow_eighteen_add_pow_fifteen (n : ℤ) : (n^2) ∣ (n^18 + n^15) := by
  exact ⟨n^16 + n^13, by ring⟩
