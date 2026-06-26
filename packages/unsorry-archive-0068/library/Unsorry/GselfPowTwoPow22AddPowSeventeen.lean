import Mathlib

theorem gself_pow_two_pow_22_add_pow_seventeen (n : ℤ) : (n^2) ∣ (n^22 + n^17) := by
  exact ⟨n^20 + n^15, by ring⟩
