import Mathlib.Data.Int.ModEq
import Mathlib.Data.ZMod.Basic

theorem dvd_264_pow_thirteen_sub_pow_three (n : ℤ) : (264 : ℤ) ∣ n ^ 13 - n ^ 3 := by
  let x := n ^ 13 - n ^ 3
  have h8d : (8 : ℤ) ∣ x := (ZMod.intCast_zmod_eq_zero_iff_dvd x 8).mp <| by
    dsimp [x]
    simpa using (by decide : ∀ a : ZMod 8, a ^ 13 - a ^ 3 = 0) (n : ZMod 8)
  have h3d : (3 : ℤ) ∣ x := (ZMod.intCast_zmod_eq_zero_iff_dvd x 3).mp <| by
    dsimp [x]
    simpa using (by decide : ∀ a : ZMod 3, a ^ 13 - a ^ 3 = 0) (n : ZMod 3)
  have h11d : (11 : ℤ) ∣ x := (ZMod.intCast_zmod_eq_zero_iff_dvd x 11).mp <| by
    dsimp [x]
    simpa using (by decide : ∀ a : ZMod 11, a ^ 13 - a ^ 3 = 0) (n : ZMod 11)
  have h8 : x ≡ 0 [ZMOD (8 : ℤ)] := h8d.modEq_zero_int
  have h3 : x ≡ 0 [ZMOD (3 : ℤ)] := h3d.modEq_zero_int
  have h11 : x ≡ 0 [ZMOD (11 : ℤ)] := h11d.modEq_zero_int
  have h24 : x ≡ 0 [ZMOD (8 : ℤ) * 3] :=
    (Int.modEq_and_modEq_iff_modEq_mul (a := x) (b := 0) (m := 8) (n := 3) (by decide)).mp
      ⟨h8, h3⟩
  have h264 : x ≡ 0 [ZMOD ((8 : ℤ) * 3) * 11] :=
    (Int.modEq_and_modEq_iff_modEq_mul (a := x) (b := 0) (m := (8 : ℤ) * 3) (n := 11)
        (by decide)).mp
      ⟨h24, h11⟩
  have h264d : ((8 : ℤ) * 3) * 11 ∣ x := Int.modEq_zero_iff_dvd.mp h264
  change (264 : ℤ) ∣ x at h264d
  change (264 : ℤ) ∣ x
  exact h264d
