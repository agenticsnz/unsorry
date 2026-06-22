import Mathlib

theorem gself_pow_29_add_pow_twelve (n : ℤ) : (n) ∣ (n^29 + n^12) := by
  exact ⟨n^28 + n^11, by ring⟩
