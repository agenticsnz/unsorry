import Mathlib

theorem gpow_diff_ten_pow_five (n : ℤ) : (n - 10) ∣ (n^5 - 100000) := by
  exact ⟨n^4 + 10*n^3 + 100*n^2 + 1000*n + 10000, by ring⟩
