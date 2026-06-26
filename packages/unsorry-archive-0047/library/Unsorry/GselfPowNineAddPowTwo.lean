import Mathlib

theorem gself_pow_nine_add_pow_two (n : ℤ) : (n) ∣ (n^9 + n^2) := by
  exact ⟨n^8 + n, by ring⟩
