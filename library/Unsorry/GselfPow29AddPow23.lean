import Mathlib

theorem gself_pow_29_add_pow_23 (n : ℤ) : (n) ∣ (n^29 + n^23) := by
  exact ⟨n^28 + n^22, by ring⟩
