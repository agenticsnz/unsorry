import Mathlib

theorem gself_pow_two_pow_sixteen_add_pow_fifteen (n : ℤ) : (n^2) ∣ (n^16 + n^15) := by
  exact ⟨n^14 + n^13, by ring⟩
