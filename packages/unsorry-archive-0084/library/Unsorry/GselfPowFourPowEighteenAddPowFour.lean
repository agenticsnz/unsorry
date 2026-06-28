import Mathlib

theorem gself_pow_four_pow_eighteen_add_pow_four (n : ℤ) : (n^4) ∣ (n^18 + n^4) := by
  exact ⟨n^14 + 1, by ring⟩
