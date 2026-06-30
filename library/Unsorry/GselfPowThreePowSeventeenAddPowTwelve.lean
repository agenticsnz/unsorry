import Mathlib

theorem gself_pow_three_pow_seventeen_add_pow_twelve (n : ℤ) : (n^3) ∣ (n^17 + n^12) := by
  exact ⟨n^14 + n^9, by ring⟩
