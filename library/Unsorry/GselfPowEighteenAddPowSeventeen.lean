import Mathlib

theorem gself_pow_eighteen_add_pow_seventeen (n : ℤ) : (n) ∣ (n^18 + n^17) := by
  exact ⟨n^17 + n^16, by ring⟩
