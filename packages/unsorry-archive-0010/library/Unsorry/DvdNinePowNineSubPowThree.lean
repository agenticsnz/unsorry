import Mathlib.Data.ZMod.Basic

/-- `9` divides `n ^ 9 - n ^ 3` for every integer `n`. -/
theorem dvd_nine_pow_nine_sub_pow_three (n : ℤ) : (9 : ℤ) ∣ n ^ 9 - n ^ 3 := by
  have hz : ((n ^ 9 - n ^ 3 : ℤ) : ZMod 9) = 0 := by
    push_cast
    have h : ∀ a : ZMod 9, a ^ 9 - a ^ 3 = 0 := by decide
    exact h (n : ZMod 9)
  simpa using (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 9 - n ^ 3) 9).mp hz
