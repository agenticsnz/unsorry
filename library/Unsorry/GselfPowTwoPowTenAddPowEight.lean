import Mathlib

theorem gself_pow_two_pow_ten_add_pow_eight (n : ℤ) : (n^2) ∣ (n^10 + n^8) := by
  exact ⟨n^8 + n^6, by ring⟩
