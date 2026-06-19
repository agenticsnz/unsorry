import Mathlib

theorem gself_pow_four_pow_thirteen_add_pow_seven (n : ℤ) : (n^4) ∣ (n^13 + n^7) := by
  exact ⟨n^9 + n^3, by ring⟩
