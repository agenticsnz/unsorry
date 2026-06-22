import Mathlib

theorem gself_pow_three_pow_23_add_pow_eighteen (n : ℤ) : (n^3) ∣ (n^23 + n^18) := by
  exact ⟨n^20 + n^15, by ring⟩
