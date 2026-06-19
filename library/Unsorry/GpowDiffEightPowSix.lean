import Mathlib

theorem gpow_diff_eight_pow_six (n : ℤ) : (n - 8) ∣ (n^6 - 262144) := by
  exact ⟨n^5 + 8*n^4 + 64*n^3 + 512*n^2 + 4096*n + 32768, by ring⟩
