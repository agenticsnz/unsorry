import Mathlib

theorem gpow_diff_three_pow_six (n : ℤ) : (n - 3) ∣ (n^6 - 729) := by
  exact ⟨n^5 + 3*n^4 + 9*n^3 + 27*n^2 + 81*n + 243, by ring⟩
