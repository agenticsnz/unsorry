import Unsorry.OddSqModEight
import Unsorry.SqModThree
import Mathlib.Data.Nat.Prime.Basic

theorem prime_sq_mod_twenty_four (p : ℕ) (hp : Nat.Prime p) (h : 3 < p) : p ^ 2 % 24 = 1 := by
  have hodd : Odd p := hp.odd_of_ne_two (by omega)
  have h8 : p ^ 2 % 8 = 1 := odd_sq_mod_eight p hodd
  have h3 : p % 3 ≠ 0 := by
    intro h0
    rcases (hp.eq_one_or_self_of_dvd 3 (Nat.dvd_of_mod_eq_zero h0)) with h1 | h1 <;> omega
  have h3' : p ^ 2 % 3 = 1 := sq_mod_three p h3
  omega
