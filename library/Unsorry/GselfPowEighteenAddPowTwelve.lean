import Mathlib

theorem gself_pow_eighteen_add_pow_twelve (n : ℤ) : (n) ∣ (n^18 + n^12) := by
  exact ⟨n^17 + n^11, by ring⟩
