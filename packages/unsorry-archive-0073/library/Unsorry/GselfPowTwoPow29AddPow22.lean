import Mathlib

theorem gself_pow_two_pow_29_add_pow_22 (n : ℤ) : (n^2) ∣ (n^29 + n^22) := by
  exact ⟨n^27 + n^20, by ring⟩
