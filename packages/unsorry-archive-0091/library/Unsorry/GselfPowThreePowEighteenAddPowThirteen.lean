import Mathlib

theorem gself_pow_three_pow_eighteen_add_pow_thirteen (n : ℤ) : (n^3) ∣ (n^18 + n^13) := by
  exact ⟨n^15 + n^10, by ring⟩
