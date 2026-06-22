import Mathlib.Data.Int.ModEq
import Mathlib.Data.ZMod.Basic

theorem dvd_455_pow_thirteen_sub_self (n : ℤ) : (455 : ℤ) ∣ n ^ 13 - n := by
  let x := n ^ 13 - n
  have h5d : (5 : ℤ) ∣ x := (ZMod.intCast_zmod_eq_zero_iff_dvd x 5).mp <| by
    dsimp [x]
    simpa using (by decide : ∀ a : ZMod 5, a ^ 13 - a = 0) (n : ZMod 5)
  have h7d : (7 : ℤ) ∣ x := (ZMod.intCast_zmod_eq_zero_iff_dvd x 7).mp <| by
    dsimp [x]
    simpa using (by decide : ∀ a : ZMod 7, a ^ 13 - a = 0) (n : ZMod 7)
  have h13d : (13 : ℤ) ∣ x := (ZMod.intCast_zmod_eq_zero_iff_dvd x 13).mp <| by
    dsimp [x]
    simpa using (by decide : ∀ a : ZMod 13, a ^ 13 - a = 0) (n : ZMod 13)
  have h5 : x ≡ 0 [ZMOD (5 : ℤ)] := h5d.modEq_zero_int
  have h7 : x ≡ 0 [ZMOD (7 : ℤ)] := h7d.modEq_zero_int
  have h13 : x ≡ 0 [ZMOD (13 : ℤ)] := h13d.modEq_zero_int
  have h35 : x ≡ 0 [ZMOD (5 : ℤ) * 7] :=
    (Int.modEq_and_modEq_iff_modEq_mul (a := x) (b := 0) (m := 5) (n := 7) (by decide)).mp
      ⟨h5, h7⟩
  have h455 : x ≡ 0 [ZMOD ((5 : ℤ) * 7) * 13] :=
    (Int.modEq_and_modEq_iff_modEq_mul (a := x) (b := 0) (m := (5 : ℤ) * 7) (n := 13)
        (by decide)).mp
      ⟨h35, h13⟩
  have h455d : ((5 : ℤ) * 7) * 13 ∣ x := Int.modEq_zero_iff_dvd.mp h455
  change (455 : ℤ) ∣ x at h455d
  change (455 : ℤ) ∣ x
  exact h455d
