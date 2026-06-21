import Mathlib

theorem gself_pow_22_add_pow_eighteen (n : ℤ) : (n) ∣ (n^22 + n^18) := by
  exact ⟨n^21 + n^17, by ring⟩
