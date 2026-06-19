import Mathlib.Data.ZMod.Basic

/-- `30` divides `n ^ 9 - n` for every integer `n`.

We reduce the divisibility to an identity in `ZMod 30`, where the statement
becomes a decidable claim about the finitely many residues. -/
theorem dvd_30_pow_nine_sub_self (n : ℤ) : (30 : ℤ) ∣ n ^ 9 - n := by
  have h : ((n ^ 9 - n : ℤ) : ZMod 30) = 0 := by
    have key : ∀ x : ZMod 30, x ^ 9 - x = 0 := by decide
    push_cast
    exact key _
  rwa [ZMod.intCast_zmod_eq_zero_iff_dvd] at h
