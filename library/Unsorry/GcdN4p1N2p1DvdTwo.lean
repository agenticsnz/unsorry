import Mathlib

theorem gcd_n4p1_n2p1_dvd_two (n : ℤ) : Int.gcd (n^4 + 1) (n^2 + 1) ∣ 2 := by
  have h1 : (↑(Int.gcd (n^4 + 1) (n^2 + 1)) : ℤ) ∣ (n^4 + 1) :=
    Int.gcd_dvd_left (n^4 + 1) (n^2 + 1)
  have h2 : (↑(Int.gcd (n^4 + 1) (n^2 + 1)) : ℤ) ∣ (n^2 + 1) :=
    Int.gcd_dvd_right (n^4 + 1) (n^2 + 1)
  have h3 : (↑(Int.gcd (n^4 + 1) (n^2 + 1)) : ℤ) ∣ 2 := by
    have hx : (↑(Int.gcd (n^4 + 1) (n^2 + 1)) : ℤ) ∣ (n^4 + 1) - (n^2 - 1) * (n^2 + 1) :=
      dvd_sub h1 (h2.mul_left (n^2 - 1))
    have heq : (n^4 + 1) - (n^2 - 1) * (n^2 + 1) = 2 := by ring
    rwa [heq] at hx
  exact_mod_cast h3
