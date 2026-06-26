import Mathlib

theorem gself_pow_25_add_pow_23 (n : ℤ) : (n) ∣ (n^25 + n^23) := by
  exact ⟨n^24 + n^22, by ring⟩
