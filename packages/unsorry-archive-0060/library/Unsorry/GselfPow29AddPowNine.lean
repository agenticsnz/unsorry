import Mathlib

theorem gself_pow_29_add_pow_nine (n : ℤ) : (n) ∣ (n^29 + n^9) := by
  exact ⟨n^28 + n^8, by ring⟩
