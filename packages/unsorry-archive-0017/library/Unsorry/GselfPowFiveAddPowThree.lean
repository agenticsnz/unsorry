import Mathlib

theorem gself_pow_five_add_pow_three (n : ℤ) : (n) ∣ (n^5 + n^3) := by
  exact ⟨n^4 + n^2, by ring⟩
