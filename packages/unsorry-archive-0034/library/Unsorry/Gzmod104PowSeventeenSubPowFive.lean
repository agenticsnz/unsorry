import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-104-pow-seventeen-sub-pow-five`: `104 ∣ n^17 - n^5` over `ℤ`, by a finite `ZMod 104` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_104_pow_seventeen_sub_pow_five (n : ℤ) : (104 : ℤ) ∣ n ^ 17 - n ^ 5 := by
  have h : ∀ m : ZMod 104, m ^ 17 - m ^ 5 = 0 := by decide
  have hz : ((n ^ 17 - n ^ 5 : ℤ) : ZMod 104) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 17 - n ^ 5) 104).mp hz
  exact_mod_cast hdvd
