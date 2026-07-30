import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-378-pow-twentythree-sub-pow-five`: `378 ∣ n^23 - n^5` over `ℤ`, by a finite `ZMod 378` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_378_pow_twentythree_sub_pow_five (n : ℤ) : (378 : ℤ) ∣ n ^ 23 - n ^ 5 := by
  have h : ∀ m : ZMod 378, m ^ 23 - m ^ 5 = 0 := by decide
  have hz : ((n ^ 23 - n ^ 5 : ℤ) : ZMod 378) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 23 - n ^ 5) 378).mp hz
  exact_mod_cast hdvd
