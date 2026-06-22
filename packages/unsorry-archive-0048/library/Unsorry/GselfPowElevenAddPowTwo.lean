import Mathlib

theorem gself_pow_eleven_add_pow_two (n : ℤ) : (n) ∣ (n^11 + n^2) := by
  exact ⟨n^10 + n, by ring⟩
