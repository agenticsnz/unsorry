import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-133-pow-twentythree-sub-pow-five`: `133 ∣ n^23 - n^5` over `ℤ`, by a finite `ZMod 133` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_133_pow_twentythree_sub_pow_five (n : ℤ) : (133 : ℤ) ∣ n ^ 23 - n ^ 5 := by
  have h : ∀ m : ZMod 133, m ^ 23 - m ^ 5 = 0 := by decide
  have hz : ((n ^ 23 - n ^ 5 : ℤ) : ZMod 133) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 23 - n ^ 5) 133).mp hz
  exact_mod_cast hdvd
