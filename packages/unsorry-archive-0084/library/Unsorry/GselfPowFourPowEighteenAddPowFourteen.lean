import Mathlib

theorem gself_pow_four_pow_eighteen_add_pow_fourteen (n : ℤ) : (n^4) ∣ (n^18 + n^14) := by
  exact ⟨n^14 + n^10, by ring⟩
