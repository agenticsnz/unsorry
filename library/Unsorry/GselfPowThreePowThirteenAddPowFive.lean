import Mathlib

theorem gself_pow_three_pow_thirteen_add_pow_five (n : ℤ) : (n^3) ∣ (n^13 + n^5) := by
  exact ⟨n^10 + n^2, by ring⟩
