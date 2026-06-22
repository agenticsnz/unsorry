import Mathlib

theorem gself_pow_22_add_pow_seventeen (n : ℤ) : (n) ∣ (n^22 + n^17) := by
  exact ⟨n^21 + n^16, by ring⟩
