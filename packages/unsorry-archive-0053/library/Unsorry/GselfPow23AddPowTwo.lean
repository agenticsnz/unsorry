import Mathlib

theorem gself_pow_23_add_pow_two (n : ℤ) : (n) ∣ (n^23 + n^2) := by
  exact ⟨n^22 + n, by ring⟩
