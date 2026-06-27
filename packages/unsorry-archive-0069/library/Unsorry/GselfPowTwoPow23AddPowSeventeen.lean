import Mathlib

theorem gself_pow_two_pow_23_add_pow_seventeen (n : ℤ) : (n^2) ∣ (n^23 + n^17) := by
  exact ⟨n^21 + n^15, by ring⟩
