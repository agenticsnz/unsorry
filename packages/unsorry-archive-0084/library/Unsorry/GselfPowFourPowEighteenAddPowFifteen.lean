import Mathlib

theorem gself_pow_four_pow_eighteen_add_pow_fifteen (n : ℤ) : (n^4) ∣ (n^18 + n^15) := by
  exact ⟨n^14 + n^11, by ring⟩
