import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-192-pow-twentythree-sub-pow-seven`: `192 ∣ n^23 - n^7` over `ℤ`, by a finite `ZMod 192` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_192_pow_twentythree_sub_pow_seven (n : ℤ) : (192 : ℤ) ∣ n ^ 23 - n ^ 7 := by
  have h : ∀ m : ZMod 192, m ^ 23 - m ^ 7 = 0 := by decide
  have hz : ((n ^ 23 - n ^ 7 : ℤ) : ZMod 192) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 23 - n ^ 7) 192).mp hz
  exact_mod_cast hdvd
