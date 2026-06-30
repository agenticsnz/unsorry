import Mathlib

theorem gself_pow_three_pow_seventeen_add_pow_sixteen (n : ℤ) : (n^3) ∣ (n^17 + n^16) := by
  exact ⟨n^14 + n^13, by ring⟩
