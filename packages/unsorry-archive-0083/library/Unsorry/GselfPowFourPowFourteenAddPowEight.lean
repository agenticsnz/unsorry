import Mathlib

theorem gself_pow_four_pow_fourteen_add_pow_eight (n : ℤ) : (n^4) ∣ (n^14 + n^8) := by
  exact ⟨n^10 + n^4, by ring⟩
