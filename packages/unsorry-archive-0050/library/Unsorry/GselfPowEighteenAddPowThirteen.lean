import Mathlib

theorem gself_pow_eighteen_add_pow_thirteen (n : ℤ) : (n) ∣ (n^18 + n^13) := by
  exact ⟨n^17 + n^12, by ring⟩
