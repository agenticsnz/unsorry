import Mathlib

theorem gself_pow_eighteen_add_pow_six (n : ℤ) : (n) ∣ (n^18 + n^6) := by
  exact ⟨n^17 + n^5, by ring⟩
