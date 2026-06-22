import Mathlib

theorem gself_pow_eighteen_add_pow_seven (n : ℤ) : (n) ∣ (n^18 + n^7) := by
  exact ⟨n^17 + n^6, by ring⟩
