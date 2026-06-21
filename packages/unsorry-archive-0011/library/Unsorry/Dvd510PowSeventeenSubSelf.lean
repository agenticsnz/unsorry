import Mathlib.Data.Int.ModEq
import Mathlib.Data.ZMod.Basic

theorem dvd_510_pow_seventeen_sub_self (n : ℤ) : (510 : ℤ) ∣ n ^ 17 - n := by
  let x := n ^ 17 - n
  have h2d : (2 : ℤ) ∣ x := (ZMod.intCast_zmod_eq_zero_iff_dvd x 2).mp <| by
    dsimp [x]
    simpa using (by decide : ∀ a : ZMod 2, a ^ 17 - a = 0) (n : ZMod 2)
  have h3d : (3 : ℤ) ∣ x := (ZMod.intCast_zmod_eq_zero_iff_dvd x 3).mp <| by
    dsimp [x]
    simpa using (by decide : ∀ a : ZMod 3, a ^ 17 - a = 0) (n : ZMod 3)
  have h5d : (5 : ℤ) ∣ x := (ZMod.intCast_zmod_eq_zero_iff_dvd x 5).mp <| by
    dsimp [x]
    simpa using (by decide : ∀ a : ZMod 5, a ^ 17 - a = 0) (n : ZMod 5)
  have h17d : (17 : ℤ) ∣ x := (ZMod.intCast_zmod_eq_zero_iff_dvd x 17).mp <| by
    dsimp [x]
    simpa using (by decide : ∀ a : ZMod 17, a ^ 17 - a = 0) (n : ZMod 17)
  have h2 : x ≡ 0 [ZMOD (2 : ℤ)] := h2d.modEq_zero_int
  have h3 : x ≡ 0 [ZMOD (3 : ℤ)] := h3d.modEq_zero_int
  have h5 : x ≡ 0 [ZMOD (5 : ℤ)] := h5d.modEq_zero_int
  have h17 : x ≡ 0 [ZMOD (17 : ℤ)] := h17d.modEq_zero_int
  have h6 : x ≡ 0 [ZMOD (2 : ℤ) * 3] :=
    (Int.modEq_and_modEq_iff_modEq_mul (a := x) (b := 0) (m := 2) (n := 3) (by decide)).mp
      ⟨h2, h3⟩
  have h30 : x ≡ 0 [ZMOD ((2 : ℤ) * 3) * 5] :=
    (Int.modEq_and_modEq_iff_modEq_mul (a := x) (b := 0) (m := (2 : ℤ) * 3) (n := 5)
        (by decide)).mp
      ⟨h6, h5⟩
  have h510 : x ≡ 0 [ZMOD (((2 : ℤ) * 3) * 5) * 17] :=
    (Int.modEq_and_modEq_iff_modEq_mul (a := x) (b := 0) (m := ((2 : ℤ) * 3) * 5)
        (n := 17) (by decide)).mp
      ⟨h30, h17⟩
  have h510d : (((2 : ℤ) * 3) * 5) * 17 ∣ x := Int.modEq_zero_iff_dvd.mp h510
  change (510 : ℤ) ∣ x at h510d
  change (510 : ℤ) ∣ x
  exact h510d
