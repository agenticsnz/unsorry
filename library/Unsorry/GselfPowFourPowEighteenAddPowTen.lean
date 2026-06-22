import Mathlib

theorem gself_pow_four_pow_eighteen_add_pow_ten (n : ℤ) : (n^4) ∣ (n^18 + n^10) := by
  exact ⟨n^14 + n^6, by ring⟩
