import Unsorry.OddFourthPowerModSixteen
import Unsorry.FourthPowerModThree
import Unsorry.FourthPowerModFive
import Mathlib.Data.Nat.Prime.Basic
import Mathlib.Data.Nat.ModEq

/-!
# `prime_fourth_power_mod_240`

For every prime `p > 5`, `p ^ 4 ≡ 1` modulo `240`.

Since `240 = 16 * 3 * 5` with the factors pairwise coprime, it suffices to show
the congruence holds modulo each factor:

* `p` is odd, so `p ^ 4 % 16 = 1` (`odd_fourth_power_mod_sixteen`);
* `3 ∤ p`, so `p ^ 4 % 3 = 1` (`fourth_power_mod_three`);
* `5 ∤ p`, so `p ^ 4 % 5 = 1` (`fourth_power_mod_five`, from
  `Unsorry.FourthPowerModFive`).

The three congruences are stitched together with
`Nat.modEq_and_modEq_iff_modEq_mul`.
-/

theorem prime_fourth_power_mod_240 (p : ℕ) (hp : Nat.Prime p) (h : 5 < p) :
    p ^ 4 % 240 = 1 := by
  -- `p` avoids each prime factor of `240`.
  have hodd : Odd p := hp.odd_of_ne_two (by omega)
  have h3 : p % 3 ≠ 0 := by
    intro hmod
    rcases hp.eq_one_or_self_of_dvd 3 (Nat.dvd_of_mod_eq_zero hmod) with h' | h' <;> omega
  have h5 : p % 5 ≠ 0 := by
    intro hmod
    rcases hp.eq_one_or_self_of_dvd 5 (Nat.dvd_of_mod_eq_zero hmod) with h' | h' <;> omega
  -- The congruence modulo each factor of `240`.
  have e16 : p ^ 4 ≡ 1 [MOD 16] := by
    show p ^ 4 % 16 = 1 % 16
    rw [odd_fourth_power_mod_sixteen p hodd]
  have e3 : p ^ 4 ≡ 1 [MOD 3] := by
    show p ^ 4 % 3 = 1 % 3
    rw [fourth_power_mod_three p h3]
  have e5 : p ^ 4 ≡ 1 [MOD 5] := by
    show p ^ 4 % 5 = 1 % 5
    rw [fourth_power_mod_five p h5]
  -- Combine across the pairwise-coprime factors.
  have e48 : p ^ 4 ≡ 1 [MOD 48] :=
    (Nat.modEq_and_modEq_iff_modEq_mul (by decide)).mp ⟨e16, e3⟩
  have e240 : p ^ 4 ≡ 1 [MOD 240] :=
    (Nat.modEq_and_modEq_iff_modEq_mul (by decide)).mp ⟨e48, e5⟩
  have h240 : p ^ 4 % 240 = 1 % 240 := e240
  omega
