import Mathlib

theorem gpow_diff_ten_pow_six (n : ℤ) : (n - 10) ∣ (n^6 - 1000000) := by
  exact ⟨n^5 + 10*n^4 + 100*n^3 + 1000*n^2 + 10000*n + 100000, by ring⟩
