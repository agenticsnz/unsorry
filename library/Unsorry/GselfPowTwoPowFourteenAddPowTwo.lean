import Mathlib

theorem gself_pow_two_pow_fourteen_add_pow_two (n : ℤ) : (n^2) ∣ (n^14 + n^2) := by
  exact ⟨n^12 + 1, by ring⟩
