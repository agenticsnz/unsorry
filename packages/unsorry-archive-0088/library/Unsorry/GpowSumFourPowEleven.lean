import Mathlib

theorem gpow_sum_four_pow_eleven (n : ℤ) : (n + 4) ∣ (n^11 + 4194304) := by
  exact ⟨n^10 - 4*n^9 + 16*n^8 - 64*n^7 + 256*n^6 - 1024*n^5 + 4096*n^4 - 16384*n^3 + 65536*n^2 - 262144*n + 1048576, by ring⟩
