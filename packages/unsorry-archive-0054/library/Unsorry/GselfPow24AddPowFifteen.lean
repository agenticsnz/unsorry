import Mathlib

theorem gself_pow_24_add_pow_fifteen (n : ℤ) : (n) ∣ (n^24 + n^15) := by
  exact ⟨n^23 + n^14, by ring⟩
