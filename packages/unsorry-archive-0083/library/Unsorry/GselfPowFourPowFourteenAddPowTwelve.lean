import Mathlib

theorem gself_pow_four_pow_fourteen_add_pow_twelve (n : ℤ) : (n^4) ∣ (n^14 + n^12) := by
  exact ⟨n^10 + n^8, by ring⟩
