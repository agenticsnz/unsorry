import Mathlib

theorem gpow_diff_seven_pow_thirteen (n : ℤ) : (n - 7) ∣ (n^13 - 96889010407) := by
  exact ⟨n^12 + 7*n^11 + 49*n^10 + 343*n^9 + 2401*n^8 + 16807*n^7 + 117649*n^6 + 823543*n^5 + 5764801*n^4 + 40353607*n^3 + 282475249*n^2 + 1977326743*n + 13841287201, by ring⟩
