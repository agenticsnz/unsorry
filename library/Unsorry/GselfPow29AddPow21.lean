import Mathlib

theorem gself_pow_29_add_pow_21 (n : ℤ) : (n) ∣ (n^29 + n^21) := by
  exact ⟨n^28 + n^20, by ring⟩
