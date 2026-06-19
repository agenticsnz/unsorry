import Mathlib

theorem gpow_diff_seven_pow_six (n : ℤ) : (n - 7) ∣ (n^6 - 117649) := by
  exact ⟨n^5 + 7*n^4 + 49*n^3 + 343*n^2 + 2401*n + 16807, by ring⟩
