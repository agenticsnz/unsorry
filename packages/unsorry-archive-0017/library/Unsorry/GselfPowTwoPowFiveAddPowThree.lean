import Mathlib

theorem gself_pow_two_pow_five_add_pow_three (n : ℤ) : (n^2) ∣ (n^5 + n^3) := by
  exact ⟨n^3 + n, by ring⟩
