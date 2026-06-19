import Mathlib

theorem gself_pow_four_pow_eighteen_add_pow_twelve (n : ℤ) : (n^4) ∣ (n^18 + n^12) := by
  exact ⟨n^14 + n^8, by ring⟩
