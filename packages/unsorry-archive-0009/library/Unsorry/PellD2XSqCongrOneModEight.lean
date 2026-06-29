import Mathlib

theorem pell_d2_x_sq_congr_one_mod_eight (x y : ℤ) (h : x ^ 2 - 2 * y ^ 2 = 1) : x ^ 2 % 8 = 1 := by
  have key : ∀ a b : ZMod 8, a ^ 2 - 2 * b ^ 2 = 1 → a ^ 2 = 1 := by decide
  have hz : (x : ZMod 8) ^ 2 - 2 * (y : ZMod 8) ^ 2 = 1 := by
    have hc := congrArg (fun t : ℤ => (t : ZMod 8)) h
    push_cast at hc
    exact hc
  have hx2 : (x : ZMod 8) ^ 2 = 1 := key _ _ hz
  have hcast0 : ((x ^ 2 - 1 : ℤ) : ZMod 8) = 0 := by
    push_cast
    rw [hx2]
    ring
  have hdvd : (8 : ℤ) ∣ (x ^ 2 - 1) := by
    exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (x ^ 2 - 1) 8).mp hcast0
  omega
