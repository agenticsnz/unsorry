import Mathlib

theorem gpow_diff_ten_pow_seven (n : ℤ) : (n - 10) ∣ (n^7 - 10000000) := by
  exact ⟨n^6 + 10*n^5 + 100*n^4 + 1000*n^3 + 10000*n^2 + 100000*n + 1000000, by ring⟩
