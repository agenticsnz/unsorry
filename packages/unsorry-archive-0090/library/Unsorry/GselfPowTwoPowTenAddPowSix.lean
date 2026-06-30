import Mathlib

theorem gself_pow_two_pow_ten_add_pow_six (n : ℤ) : (n^2) ∣ (n^10 + n^6) := by
  exact ⟨n^8 + n^4, by ring⟩
