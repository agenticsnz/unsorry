import Mathlib

theorem gself_pow_ten_add_pow_five (n : ℤ) : (n) ∣ (n^10 + n^5) := by
  exact ⟨n^9 + n^4, by ring⟩
