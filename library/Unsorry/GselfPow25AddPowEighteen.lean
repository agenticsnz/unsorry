import Mathlib

theorem gself_pow_25_add_pow_eighteen (n : ℤ) : (n) ∣ (n^25 + n^18) := by
  exact ⟨n^24 + n^17, by ring⟩
