import Mathlib

theorem gself_pow_30_add_pow_eleven (n : ℤ) : (n) ∣ (n^30 + n^11) := by
  exact ⟨n^29 + n^10, by ring⟩
