import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-160-pow-twentythree-sub-pow-seven`: `160 ∣ n^23 - n^7` over `ℤ`, by a finite `ZMod 160` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_160_pow_twentythree_sub_pow_seven (n : ℤ) : (160 : ℤ) ∣ n ^ 23 - n ^ 7 := by
  have h : ∀ m : ZMod 160, m ^ 23 - m ^ 7 = 0 := by decide
  have hz : ((n ^ 23 - n ^ 7 : ℤ) : ZMod 160) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 23 - n ^ 7) 160).mp hz
  exact_mod_cast hdvd
