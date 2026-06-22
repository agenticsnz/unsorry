import Mathlib

theorem gself_pow_29_add_pow_eight (n : ℤ) : (n) ∣ (n^29 + n^8) := by
  exact ⟨n^28 + n^7, by ring⟩
