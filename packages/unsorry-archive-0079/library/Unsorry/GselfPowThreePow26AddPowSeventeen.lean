import Mathlib

theorem gself_pow_three_pow_26_add_pow_seventeen (n : ℤ) : (n^3) ∣ (n^26 + n^17) := by
  exact ⟨n^23 + n^14, by ring⟩
