import Mathlib.NumberTheory.Divisors

theorem sum_divisors_eq_succ_of_prime (q : ℕ) (hq : Nat.Prime q) :
    ∑ d ∈ Nat.divisors q, d = q + 1 := by
  rw [hq.divisors, Finset.sum_pair hq.one_lt.ne]
  omega
