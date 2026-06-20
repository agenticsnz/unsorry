import Mathlib

set_option maxRecDepth 40000 in
theorem gbinom_poly_nmulnpow2p2 (n : ℤ) : (3 : ℤ) ∣ (n * (n ^ 2 + 2)) := by
  have h : ∀ m : ZMod 3, m * (m ^ 2 + 2) = 0 := by decide
  have hz : ((n * (n ^ 2 + 2) : ℤ) : ZMod 3) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n * (n ^ 2 + 2)) 3).mp hz
  exact_mod_cast hdvd
