import Mathlib

theorem gpow_diff_ten_pow_eight (n : ℤ) : (n - 10) ∣ (n^8 - 100000000) := by
  exact ⟨n^7 + 10*n^6 + 100*n^5 + 1000*n^4 + 10000*n^3 + 100000*n^2 + 1000000*n + 10000000, by ring⟩
