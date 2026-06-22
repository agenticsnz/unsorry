import Mathlib

theorem gself_pow_eighteen_add_pow_fifteen (n : ℤ) : (n) ∣ (n^18 + n^15) := by
  exact ⟨n^17 + n^14, by ring⟩
