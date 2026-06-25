import Mathlib

theorem gself_pow_24_add_pow_seventeen (n : ℤ) : (n) ∣ (n^24 + n^17) := by
  exact ⟨n^23 + n^16, by ring⟩
