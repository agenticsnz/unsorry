import Mathlib

theorem gself_pow_ten_add_pow_four (n : ℤ) : (n) ∣ (n^10 + n^4) := by
  exact ⟨n^9 + n^3, by ring⟩
