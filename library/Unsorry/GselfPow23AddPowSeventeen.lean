import Mathlib

theorem gself_pow_23_add_pow_seventeen (n : ℤ) : (n) ∣ (n^23 + n^17) := by
  exact ⟨n^22 + n^16, by ring⟩
