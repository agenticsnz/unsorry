import Mathlib

theorem gself_pow_six_add_pow_two (n : ℤ) : (n) ∣ (n^6 + n^2) := by
  exact ⟨n^5 + n, by ring⟩
