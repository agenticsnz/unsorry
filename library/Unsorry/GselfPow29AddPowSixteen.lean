import Mathlib

theorem gself_pow_29_add_pow_sixteen (n : ℤ) : (n) ∣ (n^29 + n^16) := by
  exact ⟨n^28 + n^15, by ring⟩
