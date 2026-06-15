import Mathlib.Data.Rat.Cast.Defs

/-!
# `nat_cast_six_eq_rat_six` (goal `platonic-schlafli-core-s1-s1-s2`)

The natural-number numeral `6` cast into `ℚ` equals the rational numeral `6`.
This is mathlib's `Nat.cast_ofNat`, instantiated at `ℚ` and `6`.
-/

theorem nat_cast_six_eq_rat_six : ((6 : ℕ) : ℚ) = (6 : ℚ) :=
  Nat.cast_ofNat
