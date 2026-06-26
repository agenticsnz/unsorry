import Mathlib

theorem gself_pow_29_add_pow_eleven (n : ℤ) : (n) ∣ (n^29 + n^11) := by
  exact ⟨n^28 + n^10, by ring⟩
