import Mathlib

theorem gself_pow_three_pow_eighteen_add_pow_seventeen (n : ℤ) : (n^3) ∣ (n^18 + n^17) := by
  exact ⟨n^15 + n^14, by ring⟩
