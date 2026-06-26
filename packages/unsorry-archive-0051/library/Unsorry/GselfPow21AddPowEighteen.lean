import Mathlib

theorem gself_pow_21_add_pow_eighteen (n : ℤ) : (n) ∣ (n^21 + n^18) := by
  exact ⟨n^20 + n^17, by ring⟩
