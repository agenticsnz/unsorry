import Mathlib

theorem gself_pow_two_pow_fourteen_add_pow_seven (n : ℤ) : (n^2) ∣ (n^14 + n^7) := by
  exact ⟨n^12 + n^5, by ring⟩
