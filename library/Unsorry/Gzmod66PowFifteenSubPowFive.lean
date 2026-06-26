import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-66-pow-fifteen-sub-pow-five`: `66 ∣ n^15 - n^5` over `ℤ`, by a finite `ZMod 66` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_66_pow_fifteen_sub_pow_five (n : ℤ) : (66 : ℤ) ∣ n ^ 15 - n ^ 5 := by
  have h : ∀ m : ZMod 66, m ^ 15 - m ^ 5 = 0 := by decide
  have hz : ((n ^ 15 - n ^ 5 : ℤ) : ZMod 66) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 15 - n ^ 5) 66).mp hz
  exact_mod_cast hdvd
