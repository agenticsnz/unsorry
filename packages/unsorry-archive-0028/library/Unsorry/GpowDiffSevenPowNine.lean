import Mathlib

theorem gpow_diff_seven_pow_nine (n : ℤ) : (n - 7) ∣ (n^9 - 40353607) := by
  exact ⟨n^8 + 7*n^7 + 49*n^6 + 343*n^5 + 2401*n^4 + 16807*n^3 + 117649*n^2 + 823543*n + 5764801, by ring⟩
