import Mathlib.Data.ZMod.Basic

/-!
# Divisibility of `n^45 - n^23` by `138`

For every integer `n`, the number `138` divides `n^45 - n^23`.

The proof reduces the statement to the finite ring `ZMod 138`: an integer is a
multiple of `138` exactly when its image in `ZMod 138` vanishes, and the
resulting identity `x^45 - x^23 = 0` is checked over all `138` residues.
-/

theorem dvd_138_pow_fortyfive_sub_pow_twentythree (n : ℤ) :
    (138 : ℤ) ∣ (n ^ 45 - n ^ 23) := by
  have h : ((n ^ 45 - n ^ 23 : ℤ) : ZMod 138) = 0 := by
    push_cast
    generalize (n : ZMod 138) = x
    revert x
    set_option maxRecDepth 4000 in decide
  rwa [ZMod.intCast_zmod_eq_zero_iff_dvd] at h
