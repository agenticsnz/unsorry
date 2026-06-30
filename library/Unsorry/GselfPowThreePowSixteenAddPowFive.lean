import Mathlib

theorem gself_pow_three_pow_sixteen_add_pow_five (n : ℤ) : (n^3) ∣ (n^16 + n^5) := by
  exact ⟨n^13 + n^2, by ring⟩
