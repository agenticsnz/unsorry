import Mathlib

theorem gself_pow_four_pow_22_add_pow_sixteen (n : ℤ) : (n^4) ∣ (n^22 + n^16) := by
  exact ⟨n^18 + n^12, by ring⟩
