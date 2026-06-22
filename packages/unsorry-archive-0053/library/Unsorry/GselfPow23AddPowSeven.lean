import Mathlib

theorem gself_pow_23_add_pow_seven (n : ℤ) : (n) ∣ (n^23 + n^7) := by
  exact ⟨n^22 + n^6, by ring⟩
