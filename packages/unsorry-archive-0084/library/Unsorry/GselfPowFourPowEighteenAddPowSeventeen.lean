import Mathlib

theorem gself_pow_four_pow_eighteen_add_pow_seventeen (n : ℤ) : (n^4) ∣ (n^18 + n^17) := by
  exact ⟨n^14 + n^13, by ring⟩
