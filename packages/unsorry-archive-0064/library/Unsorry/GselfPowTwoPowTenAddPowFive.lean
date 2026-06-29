import Mathlib

theorem gself_pow_two_pow_ten_add_pow_five (n : ℤ) : (n^2) ∣ (n^10 + n^5) := by
  exact ⟨n^8 + n^3, by ring⟩
