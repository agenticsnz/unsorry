import Mathlib

theorem gself_pow_21_add_pow_seventeen (n : ℤ) : (n) ∣ (n^21 + n^17) := by
  exact ⟨n^20 + n^16, by ring⟩
