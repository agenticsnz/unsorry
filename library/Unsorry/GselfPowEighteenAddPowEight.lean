import Mathlib

theorem gself_pow_eighteen_add_pow_eight (n : ℤ) : (n) ∣ (n^18 + n^8) := by
  exact ⟨n^17 + n^7, by ring⟩
