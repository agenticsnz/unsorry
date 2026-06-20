import Mathlib

set_option maxRecDepth 40000 in
theorem gbinom_falling_seven_fact_dvd (n : ℤ) : (5040 : ℤ) ∣ (n * (n - 1) * (n - 2) * (n - 3) * (n - 4) * (n - 5) * (n - 6)) := by
  have h : ∀ m : ZMod 5040, m * (m - 1) * (m - 2) * (m - 3) * (m - 4) * (m - 5) * (m - 6) = 0 := by decide
  have hz : ((n * (n - 1) * (n - 2) * (n - 3) * (n - 4) * (n - 5) * (n - 6) : ℤ) : ZMod 5040) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n * (n - 1) * (n - 2) * (n - 3) * (n - 4) * (n - 5) * (n - 6)) 5040).mp hz
  exact_mod_cast hdvd
