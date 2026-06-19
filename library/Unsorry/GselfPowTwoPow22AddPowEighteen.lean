import Mathlib

theorem gself_pow_two_pow_22_add_pow_eighteen (n : ℤ) : (n^2) ∣ (n^22 + n^18) := by
  exact ⟨n^20 + n^16, by ring⟩
