import Mathlib.Data.ZMod.Basic

/-!
# Divisibility: `66 ∣ n ^ 11 - n`

Since `66 = 2 * 3 * 11`, the statement reduces to checking the finite
identity `x ^ 11 - x = 0` for every `x : ZMod 66`, which is decidable.
-/

theorem dvd_66_pow_eleven_sub_self (n : ℤ) : (66 : ℤ) ∣ n ^ 11 - n := by
  have key : ∀ x : ZMod 66, x ^ 11 - x = 0 := by decide
  have h : ((n ^ 11 - n : ℤ) : ZMod 66) = 0 := by
    push_cast
    exact key _
  exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd _ 66).mp h
