import Mathlib

theorem gself_pow_three_pow_fourteen_add_pow_four (n : ℤ) : (n^3) ∣ (n^14 + n^4) := by
  exact ⟨n^11 + n, by ring⟩
