import Mathlib

theorem gself_pow_27_add_pow_two (n : ℤ) : (n) ∣ (n^27 + n^2) := by
  exact ⟨n^26 + n, by ring⟩
