import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `factorial-dvd-consec-two`: `2 ∣` the product of 2 consecutive integers `n * (n + 1)`,
by a finite `ZMod 2` case check lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. -/
theorem factorial_dvd_consec_two (n : ℤ) : (2 : ℤ) ∣ n * (n + 1) := by
  have h : ∀ m : ZMod 2, m * (m + 1) = 0 := by decide
  have hz : ((n * (n + 1) : ℤ) : ZMod 2) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n * (n + 1)) 2).mp hz
  exact_mod_cast hdvd
