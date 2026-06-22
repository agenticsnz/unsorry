import Mathlib

theorem gself_pow_twelve_add_pow_two (n : ℤ) : (n) ∣ (n^12 + n^2) := by
  exact ⟨n^11 + n, by ring⟩
