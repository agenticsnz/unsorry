import Mathlib

theorem gself_pow_ten_add_pow_eight (n : ℤ) : (n) ∣ (n^10 + n^8) := by
  exact ⟨n^9 + n^7, by ring⟩
