import Mathlib

theorem gpow_diff_ten_pow_ten (n : ℤ) : (n - 10) ∣ (n^10 - 10000000000) := by
  exact ⟨n^9 + 10*n^8 + 100*n^7 + 1000*n^6 + 10000*n^5 + 100000*n^4 + 1000000*n^3 + 10000000*n^2 + 100000000*n + 1000000000, by ring⟩
