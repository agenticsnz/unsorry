import Mathlib

theorem gself_pow_sixteen_add_pow_fifteen (n : ℤ) : (n) ∣ (n^16 + n^15) := by
  exact ⟨n^15 + n^14, by ring⟩
