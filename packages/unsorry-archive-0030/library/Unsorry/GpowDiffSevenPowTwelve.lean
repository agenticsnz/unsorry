import Mathlib

theorem gpow_diff_seven_pow_twelve (n : ℤ) : (n - 7) ∣ (n^12 - 13841287201) := by
  exact ⟨n^11 + 7*n^10 + 49*n^9 + 343*n^8 + 2401*n^7 + 16807*n^6 + 117649*n^5 + 823543*n^4 + 5764801*n^3 + 40353607*n^2 + 282475249*n + 1977326743, by ring⟩
