import Mathlib

theorem gself_pow_eighteen_add_pow_five (n : ℤ) : (n) ∣ (n^18 + n^5) := by
  exact ⟨n^17 + n^4, by ring⟩
