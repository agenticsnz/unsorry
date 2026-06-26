import Mathlib

theorem gself_pow_two_pow_fourteen_add_pow_ten (n : ℤ) : (n^2) ∣ (n^14 + n^10) := by
  exact ⟨n^12 + n^8, by ring⟩
