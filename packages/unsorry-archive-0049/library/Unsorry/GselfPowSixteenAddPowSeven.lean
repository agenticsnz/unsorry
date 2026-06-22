import Mathlib

theorem gself_pow_sixteen_add_pow_seven (n : ℤ) : (n) ∣ (n^16 + n^7) := by
  exact ⟨n^15 + n^6, by ring⟩
