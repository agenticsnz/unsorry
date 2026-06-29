import Mathlib

theorem gself_pow_three_pow_23_add_pow_five (n : ℤ) : (n^3) ∣ (n^23 + n^5) := by
  exact ⟨n^20 + n^2, by ring⟩
