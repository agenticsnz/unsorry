import Mathlib

theorem gpow_sum_eight_pow_seven (n : ℤ) : (n + 8) ∣ (n^7 + 2097152) := by
  exact ⟨n^6 - 8*n^5 + 64*n^4 - 512*n^3 + 4096*n^2 - 32768*n + 262144, by ring⟩
