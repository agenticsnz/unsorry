import Mathlib.Data.Int.ModEq
import Mathlib.Data.ZMod.Basic

theorem dvd_798_pow_nineteen_sub_self (n : ℤ) : (798 : ℤ) ∣ n ^ 19 - n := by
  let x := n ^ 19 - n
  have h2d : (2 : ℤ) ∣ x := (ZMod.intCast_zmod_eq_zero_iff_dvd x 2).mp <| by
    dsimp [x]
    simpa using (by decide : ∀ a : ZMod 2, a ^ 19 - a = 0) (n : ZMod 2)
  have h3d : (3 : ℤ) ∣ x := (ZMod.intCast_zmod_eq_zero_iff_dvd x 3).mp <| by
    dsimp [x]
    simpa using (by decide : ∀ a : ZMod 3, a ^ 19 - a = 0) (n : ZMod 3)
  have h7d : (7 : ℤ) ∣ x := (ZMod.intCast_zmod_eq_zero_iff_dvd x 7).mp <| by
    dsimp [x]
    simpa using (by decide : ∀ a : ZMod 7, a ^ 19 - a = 0) (n : ZMod 7)
  have h19d : (19 : ℤ) ∣ x := (ZMod.intCast_zmod_eq_zero_iff_dvd x 19).mp <| by
    dsimp [x]
    simpa using (by decide : ∀ a : ZMod 19, a ^ 19 - a = 0) (n : ZMod 19)
  have h2 : x ≡ 0 [ZMOD (2 : ℤ)] := h2d.modEq_zero_int
  have h3 : x ≡ 0 [ZMOD (3 : ℤ)] := h3d.modEq_zero_int
  have h7 : x ≡ 0 [ZMOD (7 : ℤ)] := h7d.modEq_zero_int
  have h19 : x ≡ 0 [ZMOD (19 : ℤ)] := h19d.modEq_zero_int
  have h6 : x ≡ 0 [ZMOD (2 : ℤ) * 3] :=
    (Int.modEq_and_modEq_iff_modEq_mul (a := x) (b := 0) (m := 2) (n := 3) (by decide)).mp
      ⟨h2, h3⟩
  have h42 : x ≡ 0 [ZMOD ((2 : ℤ) * 3) * 7] :=
    (Int.modEq_and_modEq_iff_modEq_mul (a := x) (b := 0) (m := (2 : ℤ) * 3) (n := 7)
        (by decide)).mp
      ⟨h6, h7⟩
  have h798 : x ≡ 0 [ZMOD (((2 : ℤ) * 3) * 7) * 19] :=
    (Int.modEq_and_modEq_iff_modEq_mul (a := x) (b := 0) (m := ((2 : ℤ) * 3) * 7)
        (n := 19) (by decide)).mp
      ⟨h42, h19⟩
  have h798d : (((2 : ℤ) * 3) * 7) * 19 ∣ x := Int.modEq_zero_iff_dvd.mp h798
  change (798 : ℤ) ∣ x at h798d
  change (798 : ℤ) ∣ x
  exact h798d
