import Mathlib

theorem gpow_diff_ten_pow_eleven (n : ℤ) : (n - 10) ∣ (n^11 - 100000000000) := by
  exact ⟨n^10 + 10*n^9 + 100*n^8 + 1000*n^7 + 10000*n^6 + 100000*n^5 + 1000000*n^4 + 10000000*n^3 + 100000000*n^2 + 1000000000*n + 10000000000, by ring⟩
