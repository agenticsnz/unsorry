import Mathlib

theorem gpow_diff_four_pow_twelve (n : ℤ) : (n - 4) ∣ (n^12 - 16777216) := by
  exact ⟨n^11 + 4*n^10 + 16*n^9 + 64*n^8 + 256*n^7 + 1024*n^6 + 4096*n^5 + 16384*n^4 + 65536*n^3 + 262144*n^2 + 1048576*n + 4194304, by ring⟩
