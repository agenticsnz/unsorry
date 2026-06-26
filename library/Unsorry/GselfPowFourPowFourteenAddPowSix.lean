import Mathlib

theorem gself_pow_four_pow_fourteen_add_pow_six (n : ℤ) : (n^4) ∣ (n^14 + n^6) := by
  exact ⟨n^10 + n^2, by ring⟩
