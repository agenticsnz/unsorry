import Mathlib

theorem gself_pow_two_pow_21_add_pow_sixteen (n : ℤ) : (n^2) ∣ (n^21 + n^16) := by
  exact ⟨n^19 + n^14, by ring⟩
