import Mathlib

theorem forty_two_dvd_pow_seven_sub_self (n : ℤ) : (42 : ℤ) ∣ n ^ 7 - n := by
  have h1 : ((n ^ 7 - n : ℤ) : ZMod 42) = (n : ZMod 42) ^ 7 - (n : ZMod 42) := by
    push_cast; rfl
  have h2 : ∀ (m : ZMod 42), m ^ 7 - m = 0 := by decide
  have h3 : ((n ^ 7 - n : ℤ) : ZMod 42) = 0 := by rw [h1, h2 (n : ZMod 42)]
  exact (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 7 - n) 42).mp h3
