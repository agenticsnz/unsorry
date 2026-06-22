import Mathlib

theorem gself_pow_23_add_pow_sixteen (n : ℤ) : (n) ∣ (n^23 + n^16) := by
  exact ⟨n^22 + n^15, by ring⟩
