import Mathlib

theorem gself_pow_three_pow_sixteen_add_pow_thirteen (n : ℤ) : (n^3) ∣ (n^16 + n^13) := by
  exact ⟨n^13 + n^10, by ring⟩
