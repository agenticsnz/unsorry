import Mathlib

theorem gself_pow_two_pow_23_add_pow_22 (n : ℤ) : (n^2) ∣ (n^23 + n^22) := by
  exact ⟨n^21 + n^20, by ring⟩
