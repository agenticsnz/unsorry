import Mathlib

theorem gself_pow_eighteen_add_pow_three (n : ℤ) : (n) ∣ (n^18 + n^3) := by
  exact ⟨n^17 + n^2, by ring⟩
