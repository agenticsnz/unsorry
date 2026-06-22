import Mathlib

theorem gpow_diff_seven_pow_eleven (n : ℤ) : (n - 7) ∣ (n^11 - 1977326743) := by
  exact ⟨n^10 + 7*n^9 + 49*n^8 + 343*n^7 + 2401*n^6 + 16807*n^5 + 117649*n^4 + 823543*n^3 + 5764801*n^2 + 40353607*n + 282475249, by ring⟩
