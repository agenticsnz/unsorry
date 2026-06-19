import Mathlib.Data.Int.ModEq
import Mathlib.Data.ZMod.Basic

theorem dvd_330_pow_twentyone_sub_self (n : ℤ) : (330 : ℤ) ∣ n ^ 21 - n := by
  let x := n ^ 21 - n
  have h2d : (2 : ℤ) ∣ x := (ZMod.intCast_zmod_eq_zero_iff_dvd x 2).mp <| by
    dsimp [x]
    simpa using (by decide : ∀ a : ZMod 2, a ^ 21 - a = 0) (n : ZMod 2)
  have h3d : (3 : ℤ) ∣ x := (ZMod.intCast_zmod_eq_zero_iff_dvd x 3).mp <| by
    dsimp [x]
    simpa using (by decide : ∀ a : ZMod 3, a ^ 21 - a = 0) (n : ZMod 3)
  have h5d : (5 : ℤ) ∣ x := (ZMod.intCast_zmod_eq_zero_iff_dvd x 5).mp <| by
    dsimp [x]
    simpa using (by decide : ∀ a : ZMod 5, a ^ 21 - a = 0) (n : ZMod 5)
  have h11d : (11 : ℤ) ∣ x := (ZMod.intCast_zmod_eq_zero_iff_dvd x 11).mp <| by
    dsimp [x]
    simpa using (by decide : ∀ a : ZMod 11, a ^ 21 - a = 0) (n : ZMod 11)
  have h2 : x ≡ 0 [ZMOD (2 : ℤ)] := h2d.modEq_zero_int
  have h3 : x ≡ 0 [ZMOD (3 : ℤ)] := h3d.modEq_zero_int
  have h5 : x ≡ 0 [ZMOD (5 : ℤ)] := h5d.modEq_zero_int
  have h11 : x ≡ 0 [ZMOD (11 : ℤ)] := h11d.modEq_zero_int
  have h6 : x ≡ 0 [ZMOD (2 : ℤ) * 3] :=
    (Int.modEq_and_modEq_iff_modEq_mul (a := x) (b := 0) (m := 2) (n := 3) (by decide)).mp
      ⟨h2, h3⟩
  have h30 : x ≡ 0 [ZMOD ((2 : ℤ) * 3) * 5] :=
    (Int.modEq_and_modEq_iff_modEq_mul (a := x) (b := 0) (m := (2 : ℤ) * 3) (n := 5)
        (by decide)).mp
      ⟨h6, h5⟩
  have h330 : x ≡ 0 [ZMOD (((2 : ℤ) * 3) * 5) * 11] :=
    (Int.modEq_and_modEq_iff_modEq_mul (a := x) (b := 0) (m := ((2 : ℤ) * 3) * 5)
        (n := 11) (by decide)).mp
      ⟨h30, h11⟩
  have h330d : (((2 : ℤ) * 3) * 5) * 11 ∣ x := Int.modEq_zero_iff_dvd.mp h330
  change (330 : ℤ) ∣ x at h330d
  change (330 : ℤ) ∣ x
  exact h330d
