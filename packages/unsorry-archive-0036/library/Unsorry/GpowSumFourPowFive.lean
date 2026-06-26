import Mathlib

theorem gpow_sum_four_pow_five (n : ℤ) : (n + 4) ∣ (n^5 + 1024) := by
  exact ⟨n^4 - 4*n^3 + 16*n^2 - 64*n + 256, by ring⟩
