import Mathlib

theorem gself_pow_three_pow_23_add_pow_21 (n : ℤ) : (n^3) ∣ (n^23 + n^21) := by
  exact ⟨n^20 + n^18, by ring⟩
