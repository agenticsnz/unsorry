import Mathlib

theorem gself_pow_four_pow_eighteen_add_pow_thirteen (n : ℤ) : (n^4) ∣ (n^18 + n^13) := by
  exact ⟨n^14 + n^9, by ring⟩
