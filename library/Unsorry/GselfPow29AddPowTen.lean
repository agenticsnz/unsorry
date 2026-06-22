import Mathlib

theorem gself_pow_29_add_pow_ten (n : ℤ) : (n) ∣ (n^29 + n^10) := by
  exact ⟨n^28 + n^9, by ring⟩
