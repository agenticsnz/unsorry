import Unsorry.PrimeSqModTwentyFour

theorem prime_sq_sub_sq_div_twenty_four (p q : ℕ) (hp : Nat.Prime p) (hq : Nat.Prime q) (hp3 : 3 < p) (hq3 : 3 < q) : (24 : ℤ) ∣ (p : ℤ) ^ 2 - (q : ℤ) ^ 2 := by
  have h1 : p ^ 2 % 24 = 1 := prime_sq_mod_twenty_four p hp hp3
  have h2 : q ^ 2 % 24 = 1 := prime_sq_mod_twenty_four q hq hq3
  have c1 : (p : ℤ) ^ 2 % 24 = 1 := by exact_mod_cast h1
  have c2 : (q : ℤ) ^ 2 % 24 = 1 := by exact_mod_cast h2
  omega
