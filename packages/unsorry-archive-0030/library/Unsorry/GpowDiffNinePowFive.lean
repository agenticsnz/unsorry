import Mathlib

theorem gpow_diff_nine_pow_five (n : ℤ) : (n - 9) ∣ (n^5 - 59049) := by
  exact ⟨n^4 + 9*n^3 + 81*n^2 + 729*n + 6561, by ring⟩
