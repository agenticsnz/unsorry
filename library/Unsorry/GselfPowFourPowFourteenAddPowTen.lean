import Mathlib

theorem gself_pow_four_pow_fourteen_add_pow_ten (n : ℤ) : (n^4) ∣ (n^14 + n^10) := by
  exact ⟨n^10 + n^6, by ring⟩
