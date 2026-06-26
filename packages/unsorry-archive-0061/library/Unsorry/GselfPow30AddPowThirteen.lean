import Mathlib

theorem gself_pow_30_add_pow_thirteen (n : ℤ) : (n) ∣ (n^30 + n^13) := by
  exact ⟨n^29 + n^12, by ring⟩
