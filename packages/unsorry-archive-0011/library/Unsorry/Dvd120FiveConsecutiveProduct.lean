import Mathlib.Data.ZMod.Basic
import Mathlib.RingTheory.Coprime.Basic
import Mathlib.Tactic

/-- `120` divides `n * (n^2 - 1) * (n^2 - 4)`, which is the product of the five
consecutive integers `(n - 2) * (n - 1) * n * (n + 1) * (n + 2)`.  We split
`120 = 8 * 3 * 5` into pairwise coprime factors and check each via residues. -/
theorem dvd_120_five_consecutive_product (n : ℤ) :
    (120 : ℤ) ∣ n * (n^2 - 1) * (n^2 - 4) := by
  have h8 : (8 : ℤ) ∣ n * (n^2 - 1) * (n^2 - 4) := by
    have h : ((n * (n^2 - 1) * (n^2 - 4) : ℤ) : ZMod 8) = 0 := by
      push_cast
      generalize (n : ZMod 8) = m
      revert m
      decide
    exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd _ 8).mp h
  have h3 : (3 : ℤ) ∣ n * (n^2 - 1) * (n^2 - 4) := by
    have h : ((n * (n^2 - 1) * (n^2 - 4) : ℤ) : ZMod 3) = 0 := by
      push_cast
      generalize (n : ZMod 3) = m
      revert m
      decide
    exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd _ 3).mp h
  have h5 : (5 : ℤ) ∣ n * (n^2 - 1) * (n^2 - 4) := by
    have h : ((n * (n^2 - 1) * (n^2 - 4) : ℤ) : ZMod 5) = 0 := by
      push_cast
      generalize (n : ZMod 5) = m
      revert m
      decide
    exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd _ 5).mp h
  have c1 : IsCoprime (8 : ℤ) 3 := ⟨-1, 3, by norm_num⟩
  have c2 : IsCoprime (8 * 3 : ℤ) 5 := ⟨-1, 5, by norm_num⟩
  have h24 : (8 * 3 : ℤ) ∣ n * (n^2 - 1) * (n^2 - 4) := c1.mul_dvd h8 h3
  have h120 : (8 * 3 * 5 : ℤ) ∣ n * (n^2 - 1) * (n^2 - 4) := c2.mul_dvd h24 h5
  have e : (8 * 3 * 5 : ℤ) = 120 := by norm_num
  rwa [e] at h120
