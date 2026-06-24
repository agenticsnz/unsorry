import Mathlib

theorem gself_pow_28_add_pow_seventeen (n : ℤ) : (n) ∣ (n^28 + n^17) := by
  exact ⟨n^27 + n^16, by ring⟩
