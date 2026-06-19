import Mathlib

theorem gself_pow_two_pow_22_add_pow_four (n : ℤ) : (n^2) ∣ (n^22 + n^4) := by
  exact ⟨n^20 + n^2, by ring⟩
