import Mathlib

theorem gpow_diff_eight_pow_four (n : ℤ) : (n - 8) ∣ (n^4 - 4096) := by
  exact ⟨n^3 + 8*n^2 + 64*n + 512, by ring⟩
