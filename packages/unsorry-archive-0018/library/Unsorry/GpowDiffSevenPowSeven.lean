import Mathlib

theorem gpow_diff_seven_pow_seven (n : ℤ) : (n - 7) ∣ (n^7 - 823543) := by
  exact ⟨n^6 + 7*n^5 + 49*n^4 + 343*n^3 + 2401*n^2 + 16807*n + 117649, by ring⟩
