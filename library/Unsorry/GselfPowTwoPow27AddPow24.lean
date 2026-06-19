import Mathlib

theorem gself_pow_two_pow_27_add_pow_24 (n : ℤ) : (n^2) ∣ (n^27 + n^24) := by
  exact ⟨n^25 + n^22, by ring⟩
