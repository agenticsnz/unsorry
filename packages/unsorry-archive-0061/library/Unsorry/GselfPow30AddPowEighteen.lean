import Mathlib

theorem gself_pow_30_add_pow_eighteen (n : ℤ) : (n) ∣ (n^30 + n^18) := by
  exact ⟨n^29 + n^17, by ring⟩
