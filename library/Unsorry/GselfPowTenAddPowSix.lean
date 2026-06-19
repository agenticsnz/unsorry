import Mathlib

theorem gself_pow_ten_add_pow_six (n : ℤ) : (n) ∣ (n^10 + n^6) := by
  exact ⟨n^9 + n^5, by ring⟩
