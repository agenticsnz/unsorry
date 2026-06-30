import Mathlib

set_option maxRecDepth 40000 in
theorem gbinom_poly_nmulnpow2m7 (n : ℤ) : (6 : ℤ) ∣ (n * (n ^ 2 - 7)) := by
  have h : ∀ m : ZMod 6, m * (m ^ 2 - 7) = 0 := by decide
  have hz : ((n * (n ^ 2 - 7) : ℤ) : ZMod 6) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n * (n ^ 2 - 7)) 6).mp hz
  exact_mod_cast hdvd
