import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-72-pow-eleven-sub-pow-five`: `72 ∣ n^11 - n^5` over `ℤ`, by a finite `ZMod 72` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_72_pow_eleven_sub_pow_five (n : ℤ) : (72 : ℤ) ∣ n ^ 11 - n ^ 5 := by
  have h : ∀ m : ZMod 72, m ^ 11 - m ^ 5 = 0 := by decide
  have hz : ((n ^ 11 - n ^ 5 : ℤ) : ZMod 72) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 11 - n ^ 5) 72).mp hz
  exact_mod_cast hdvd
