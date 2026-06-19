import Mathlib

theorem gself_pow_25_add_pow_seventeen (n : ℤ) : (n) ∣ (n^25 + n^17) := by
  exact ⟨n^24 + n^16, by ring⟩
