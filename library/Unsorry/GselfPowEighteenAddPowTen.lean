import Mathlib

theorem gself_pow_eighteen_add_pow_ten (n : ℤ) : (n) ∣ (n^18 + n^10) := by
  exact ⟨n^17 + n^9, by ring⟩
