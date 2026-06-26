import Mathlib

theorem gself_pow_eighteen_add_pow_sixteen (n : ℤ) : (n) ∣ (n^18 + n^16) := by
  exact ⟨n^17 + n^15, by ring⟩
