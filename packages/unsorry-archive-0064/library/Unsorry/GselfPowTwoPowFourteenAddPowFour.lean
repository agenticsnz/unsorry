import Mathlib

theorem gself_pow_two_pow_fourteen_add_pow_four (n : ℤ) : (n^2) ∣ (n^14 + n^4) := by
  exact ⟨n^12 + n^2, by ring⟩
