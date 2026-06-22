import Mathlib

theorem gself_pow_25_add_pow_22 (n : ℤ) : (n) ∣ (n^25 + n^22) := by
  exact ⟨n^24 + n^21, by ring⟩
