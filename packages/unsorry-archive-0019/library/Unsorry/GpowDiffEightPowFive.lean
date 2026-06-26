import Mathlib

theorem gpow_diff_eight_pow_five (n : ℤ) : (n - 8) ∣ (n^5 - 32768) := by
  exact ⟨n^4 + 8*n^3 + 64*n^2 + 512*n + 4096, by ring⟩
