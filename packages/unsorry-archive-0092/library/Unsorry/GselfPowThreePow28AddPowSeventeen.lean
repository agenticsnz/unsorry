import Mathlib

theorem gself_pow_three_pow_28_add_pow_seventeen (n : ℤ) : (n^3) ∣ (n^28 + n^17) := by
  exact ⟨n^25 + n^14, by ring⟩
