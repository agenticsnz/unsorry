import Mathlib

theorem gself_pow_fourteen_add_pow_two (n : ℤ) : (n) ∣ (n^14 + n^2) := by
  exact ⟨n^13 + n, by ring⟩
