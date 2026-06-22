import Mathlib

theorem gself_pow_three_add_pow_one (n : ℤ) : (n) ∣ (n^3 + n) := by
  exact ⟨n^2 + 1, by ring⟩
