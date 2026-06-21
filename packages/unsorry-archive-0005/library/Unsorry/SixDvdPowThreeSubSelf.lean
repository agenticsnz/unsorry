import Mathlib.Data.ZMod.Basic

theorem six_dvd_pow_three_sub_self (n : ℤ) : (6 : ℤ) ∣ n ^ 3 - n := by
  have h1 : ((n ^ 3 - n : ℤ) : ZMod 6) = (n : ZMod 6) ^ 3 - (n : ZMod 6) := by
    push_cast; rfl
  have h2 : ∀ (m : ZMod 6), m ^ 3 - m = 0 := by decide
  have h3 : ((n ^ 3 - n : ℤ) : ZMod 6) = 0 := by rw [h1, h2 (n : ZMod 6)]
  exact (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 3 - n) 6).mp h3
