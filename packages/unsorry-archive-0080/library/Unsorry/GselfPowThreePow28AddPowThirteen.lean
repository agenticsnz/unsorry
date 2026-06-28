import Mathlib

theorem gself_pow_three_pow_28_add_pow_thirteen (n : ℤ) : (n^3) ∣ (n^28 + n^13) := by
  exact ⟨n^25 + n^10, by ring⟩
