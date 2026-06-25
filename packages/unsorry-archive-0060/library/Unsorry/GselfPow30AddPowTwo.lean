import Mathlib

theorem gself_pow_30_add_pow_two (n : ℤ) : (n) ∣ (n^30 + n^2) := by
  exact ⟨n^29 + n, by ring⟩
