import Mathlib

theorem gself_pow_four_pow_nine_add_pow_five (n : ℤ) : (n^4) ∣ (n^9 + n^5) := by
  exact ⟨n^5 + n, by ring⟩
