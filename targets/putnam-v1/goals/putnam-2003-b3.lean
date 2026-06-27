import Mathlib

open MvPolynomial Set Nat

theorem putnam_2003_b3 (n : ℕ) :
    n ! = ∏ i ∈ Finset.Icc 1 n, ((List.range ⌊n / i⌋₊).map succ).foldl Nat.lcm 1 := by
  sorry
