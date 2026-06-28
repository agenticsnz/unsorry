import Mathlib

theorem gpow_sum_one_pow_nineteen (n : ℤ) : (n + 1) ∣ (n^19 + 1) := by
  exact ⟨n^18 - n^17 + n^16 - n^15 + n^14 - n^13 + n^12 - n^11 + n^10 - n^9 + n^8 - n^7 + n^6 - n^5 + n^4 - n^3 + n^2 - n + 1, by ring⟩
