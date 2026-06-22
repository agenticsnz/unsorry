import Mathlib

theorem gpow_diff_four_pow_four (n : ℤ) : (n - 4) ∣ (n^4 - 256) := by
  exact ⟨n^3 + 4*n^2 + 16*n + 64, by ring⟩
