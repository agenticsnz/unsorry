import Mathlib

theorem gself_pow_two_pow_25_add_pow_24 (n : ℤ) : (n^2) ∣ (n^25 + n^24) := by
  exact ⟨n^23 + n^22, by ring⟩
