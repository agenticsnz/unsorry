import Mathlib

theorem gself_pow_fifteen_add_pow_two (n : ℤ) : (n) ∣ (n^15 + n^2) := by
  exact ⟨n^14 + n, by ring⟩
