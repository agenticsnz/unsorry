import Mathlib

theorem gself_pow_ten_add_pow_three (n : ℤ) : (n) ∣ (n^10 + n^3) := by
  exact ⟨n^9 + n^2, by ring⟩
