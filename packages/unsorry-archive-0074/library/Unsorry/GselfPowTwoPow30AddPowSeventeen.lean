import Mathlib

theorem gself_pow_two_pow_30_add_pow_seventeen (n : ℤ) : (n^2) ∣ (n^30 + n^17) := by
  exact ⟨n^28 + n^15, by ring⟩
