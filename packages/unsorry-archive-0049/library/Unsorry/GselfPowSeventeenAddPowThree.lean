import Mathlib

theorem gself_pow_seventeen_add_pow_three (n : ℤ) : (n) ∣ (n^17 + n^3) := by
  exact ⟨n^16 + n^2, by ring⟩
