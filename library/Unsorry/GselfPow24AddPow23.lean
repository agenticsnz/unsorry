import Mathlib

theorem gself_pow_24_add_pow_23 (n : ℤ) : (n) ∣ (n^24 + n^23) := by
  exact ⟨n^23 + n^22, by ring⟩
