import Mathlib

theorem gself_pow_three_pow_thirteen_add_pow_six (n : ℤ) : (n^3) ∣ (n^13 + n^6) := by
  exact ⟨n^10 + n^3, by ring⟩
