import Mathlib

theorem gself_pow_two_pow_22_add_pow_five (n : ℤ) : (n^2) ∣ (n^22 + n^5) := by
  exact ⟨n^20 + n^3, by ring⟩
