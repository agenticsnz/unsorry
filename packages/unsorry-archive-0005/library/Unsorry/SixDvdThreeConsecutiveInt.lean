import Mathlib.Data.ZMod.Basic

theorem six_dvd_three_consecutive_int (n : ℤ) : (6 : ℤ) ∣ n * (n + 1) * (n + 2) := by
  have h1 : ((n * (n + 1) * (n + 2) : ℤ) : ZMod 6)
      = (n : ZMod 6) * ((n : ZMod 6) + 1) * ((n : ZMod 6) + 2) := by
    push_cast; rfl
  have h2 : ∀ (m : ZMod 6), m * (m + 1) * (m + 2) = 0 := by decide
  have h3 : ((n * (n + 1) * (n + 2) : ℤ) : ZMod 6) = 0 := by rw [h1, h2 (n : ZMod 6)]
  exact (ZMod.intCast_zmod_eq_zero_iff_dvd (n * (n + 1) * (n + 2)) 6).mp h3
