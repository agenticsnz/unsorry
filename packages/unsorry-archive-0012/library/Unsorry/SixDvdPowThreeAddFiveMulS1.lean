import Mathlib

theorem two_dvd_pow_three_add_five_mul (n : ℤ) : (2 : ℤ) ∣ n ^ 3 + 5 * n := by
  obtain ⟨k, rfl⟩ | ⟨k, rfl⟩ := Int.even_or_odd n
  · use k * (4 * k ^ 2 + 5)
    ring
  · use (2 * k + 1) * (2 * k ^ 2 + 2 * k + 3)
    ring