import Mathlib

theorem gself_pow_five_add_pow_two (n : ℤ) : (n) ∣ (n^5 + n^2) := by
  exact ⟨n^4 + n, by ring⟩
