import Mathlib

theorem gself_pow_four_add_pow_one (n : ℤ) : (n) ∣ (n^4 + n) := by
  exact ⟨n^3 + 1, by ring⟩
