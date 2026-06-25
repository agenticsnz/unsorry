import Mathlib

theorem gself_pow_29_add_pow_25 (n : ℤ) : (n) ∣ (n^29 + n^25) := by
  exact ⟨n^28 + n^24, by ring⟩
