import Mathlib

theorem gself_pow_30_add_pow_seventeen (n : ℤ) : (n) ∣ (n^30 + n^17) := by
  exact ⟨n^29 + n^16, by ring⟩
