import Mathlib

theorem gself_pow_fifteen_add_pow_seven (n : ℤ) : (n) ∣ (n^15 + n^7) := by
  exact ⟨n^14 + n^6, by ring⟩
