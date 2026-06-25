import Mathlib

theorem gself_pow_30_add_pow_twenty (n : ℤ) : (n) ∣ (n^30 + n^20) := by
  exact ⟨n^29 + n^19, by ring⟩
