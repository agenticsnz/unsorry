import Mathlib

theorem gpow_diff_three_pow_seven (n : ℤ) : (n - 3) ∣ (n^7 - 2187) := by
  exact ⟨n^6 + 3*n^5 + 9*n^4 + 27*n^3 + 81*n^2 + 243*n + 729, by ring⟩
