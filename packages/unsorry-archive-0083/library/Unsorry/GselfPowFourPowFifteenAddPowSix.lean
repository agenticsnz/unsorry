import Mathlib

theorem gself_pow_four_pow_fifteen_add_pow_six (n : ℤ) : (n^4) ∣ (n^15 + n^6) := by
  exact ⟨n^11 + n^2, by ring⟩
