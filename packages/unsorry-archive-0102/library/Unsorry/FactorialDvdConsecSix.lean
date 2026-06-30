import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `factorial-dvd-consec-six`: `720 ∣` the product of 6 consecutive integers `n * (n + 1) * (n + 2) * (n + 3) * (n + 4) * (n + 5)`,
by a finite `ZMod 720` case check lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. -/
theorem factorial_dvd_consec_six (n : ℤ) : (720 : ℤ) ∣ n * (n + 1) * (n + 2) * (n + 3) * (n + 4) * (n + 5) := by
  have h : ∀ m : ZMod 720, m * (m + 1) * (m + 2) * (m + 3) * (m + 4) * (m + 5) = 0 := by decide
  have hz : ((n * (n + 1) * (n + 2) * (n + 3) * (n + 4) * (n + 5) : ℤ) : ZMod 720) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n * (n + 1) * (n + 2) * (n + 3) * (n + 4) * (n + 5)) 720).mp hz
  exact_mod_cast hdvd
