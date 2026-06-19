import Mathlib

theorem gself_pow_sixteen_add_pow_four (n : ℤ) : (n) ∣ (n^16 + n^4) := by
  exact ⟨n^15 + n^3, by ring⟩
