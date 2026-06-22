import Mathlib

theorem gpow_diff_ten_pow_four (n : ℤ) : (n - 10) ∣ (n^4 - 10000) := by
  exact ⟨n^3 + 10*n^2 + 100*n + 1000, by ring⟩
