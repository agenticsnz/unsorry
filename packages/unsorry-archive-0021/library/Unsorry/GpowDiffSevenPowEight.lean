import Mathlib

theorem gpow_diff_seven_pow_eight (n : ℤ) : (n - 7) ∣ (n^8 - 5764801) := by
  exact ⟨n^7 + 7*n^6 + 49*n^5 + 343*n^4 + 2401*n^3 + 16807*n^2 + 117649*n + 823543, by ring⟩
