import Mathlib

theorem gself_pow_29_add_pow_four (n : ℤ) : (n) ∣ (n^29 + n^4) := by
  exact ⟨n^28 + n^3, by ring⟩
