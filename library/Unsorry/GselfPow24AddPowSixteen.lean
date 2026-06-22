import Mathlib

theorem gself_pow_24_add_pow_sixteen (n : ℤ) : (n) ∣ (n^24 + n^16) := by
  exact ⟨n^23 + n^15, by ring⟩
