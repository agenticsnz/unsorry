import Mathlib

theorem gpow_sum_four_pow_six (n : ℤ) : (n + 4) ∣ (n^6 - 4096) := by
  exact ⟨n^5 - 4*n^4 + 16*n^3 - 64*n^2 + 256*n - 1024, by ring⟩
