import Mathlib

theorem gpow_sum_five_pow_four (n : ℤ) : (n + 5) ∣ (n^4 - 625) := by
  exact ⟨n^3 - 5*n^2 + 25*n - 125, by ring⟩
