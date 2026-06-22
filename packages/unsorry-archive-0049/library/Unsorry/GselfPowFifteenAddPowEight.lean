import Mathlib

theorem gself_pow_fifteen_add_pow_eight (n : ℤ) : (n) ∣ (n^15 + n^8) := by
  exact ⟨n^14 + n^7, by ring⟩
