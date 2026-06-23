import Mathlib

theorem gself_pow_25_add_pow_two (n : ℤ) : (n) ∣ (n^25 + n^2) := by
  exact ⟨n^24 + n, by ring⟩
