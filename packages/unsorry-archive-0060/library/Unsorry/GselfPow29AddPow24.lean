import Mathlib

theorem gself_pow_29_add_pow_24 (n : ℤ) : (n) ∣ (n^29 + n^24) := by
  exact ⟨n^28 + n^23, by ring⟩
