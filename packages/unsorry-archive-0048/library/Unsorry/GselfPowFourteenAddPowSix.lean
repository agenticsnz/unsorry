import Mathlib

theorem gself_pow_fourteen_add_pow_six (n : ℤ) : (n) ∣ (n^14 + n^6) := by
  exact ⟨n^13 + n^5, by ring⟩
