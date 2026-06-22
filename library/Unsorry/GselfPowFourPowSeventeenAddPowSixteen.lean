import Mathlib

theorem gself_pow_four_pow_seventeen_add_pow_sixteen (n : ℤ) : (n^4) ∣ (n^17 + n^16) := by
  exact ⟨n^13 + n^12, by ring⟩
