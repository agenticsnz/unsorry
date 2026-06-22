import Mathlib

theorem gself_pow_30_add_pow_28 (n : ℤ) : (n) ∣ (n^30 + n^28) := by
  exact ⟨n^29 + n^27, by ring⟩
