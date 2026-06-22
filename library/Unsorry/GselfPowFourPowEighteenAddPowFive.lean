import Mathlib

theorem gself_pow_four_pow_eighteen_add_pow_five (n : ℤ) : (n^4) ∣ (n^18 + n^5) := by
  exact ⟨n^14 + n, by ring⟩
