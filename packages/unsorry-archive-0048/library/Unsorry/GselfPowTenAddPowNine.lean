import Mathlib

theorem gself_pow_ten_add_pow_nine (n : ℤ) : (n) ∣ (n^10 + n^9) := by
  exact ⟨n^9 + n^8, by ring⟩
