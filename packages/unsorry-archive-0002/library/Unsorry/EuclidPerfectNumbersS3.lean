import Mathlib

theorem sum_divisors_mul_of_coprime (m n : ℕ) (h : Nat.Coprime m n) :
    ∑ d ∈ Nat.divisors (m * n), d = (∑ d ∈ Nat.divisors m, d) * (∑ d ∈ Nat.divisors n, d) :=
  Nat.Coprime.sum_divisors_mul h
