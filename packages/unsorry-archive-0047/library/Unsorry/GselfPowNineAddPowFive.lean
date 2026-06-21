import Mathlib

theorem gself_pow_nine_add_pow_five (n : ℤ) : (n) ∣ (n^9 + n^5) := by
  exact ⟨n^8 + n^4, by ring⟩
