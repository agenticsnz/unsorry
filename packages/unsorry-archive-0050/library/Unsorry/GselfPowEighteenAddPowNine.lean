import Mathlib

theorem gself_pow_eighteen_add_pow_nine (n : ℤ) : (n) ∣ (n^18 + n^9) := by
  exact ⟨n^17 + n^8, by ring⟩
