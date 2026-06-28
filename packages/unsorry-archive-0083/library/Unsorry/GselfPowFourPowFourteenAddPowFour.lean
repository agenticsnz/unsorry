import Mathlib

theorem gself_pow_four_pow_fourteen_add_pow_four (n : ℤ) : (n^4) ∣ (n^14 + n^4) := by
  exact ⟨n^10 + 1, by ring⟩
