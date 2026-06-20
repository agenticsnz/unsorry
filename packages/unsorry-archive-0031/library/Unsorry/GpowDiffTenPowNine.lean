import Mathlib

theorem gpow_diff_ten_pow_nine (n : ℤ) : (n - 10) ∣ (n^9 - 1000000000) := by
  exact ⟨n^8 + 10*n^7 + 100*n^6 + 1000*n^5 + 10000*n^4 + 100000*n^3 + 1000000*n^2 + 10000000*n + 100000000, by ring⟩
