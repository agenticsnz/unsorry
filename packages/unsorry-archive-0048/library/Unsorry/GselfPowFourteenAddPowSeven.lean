import Mathlib

theorem gself_pow_fourteen_add_pow_seven (n : ℤ) : (n) ∣ (n^14 + n^7) := by
  exact ⟨n^13 + n^6, by ring⟩
