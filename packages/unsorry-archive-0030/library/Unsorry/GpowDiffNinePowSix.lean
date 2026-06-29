import Mathlib

theorem gpow_diff_nine_pow_six (n : ℤ) : (n - 9) ∣ (n^6 - 531441) := by
  exact ⟨n^5 + 9*n^4 + 81*n^3 + 729*n^2 + 6561*n + 59049, by ring⟩
