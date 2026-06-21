import Mathlib

theorem gpow_diff_four_pow_fourteen (n : ℤ) : (n - 4) ∣ (n^14 - 268435456) := by
  exact ⟨n^13 + 4*n^12 + 16*n^11 + 64*n^10 + 256*n^9 + 1024*n^8 + 4096*n^7 + 16384*n^6 + 65536*n^5 + 262144*n^4 + 1048576*n^3 + 4194304*n^2 + 16777216*n + 67108864, by ring⟩
