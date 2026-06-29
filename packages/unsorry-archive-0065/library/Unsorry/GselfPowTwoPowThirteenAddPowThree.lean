import Mathlib

theorem gself_pow_two_pow_thirteen_add_pow_three (n : ℤ) : (n^2) ∣ (n^13 + n^3) := by
  exact ⟨n^11 + n, by ring⟩
