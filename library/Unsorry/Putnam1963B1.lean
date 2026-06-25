import Mathlib

open Polynomial

/-- Putnam 1963 B1 answer: the unique integer `a` for which `X^2 - X + C a`
divides `X^13 + X + C 90`. -/
abbrev putnam_1963_b1_solution : ℤ := 2

/-- Putnam 1963 B1: over `ℤ[X]`, the quadratic `X^2 - X + C a` divides
`X^13 + X + C 90` exactly when `a = 2`.

For the forward direction, evaluating the divisibility at `0` and `1` forces
`a ∣ 90` and `a ∣ 92`, hence `a ∣ 2`, leaving only `a ∈ {-2, -1, 0, 1, 2}`;
each of the four wrong values is ruled out by evaluating at a single point.
For the reverse direction we exhibit the explicit cofactor. -/
theorem putnam_1963_b1 :
    ∀ a : ℤ, (X^2 - X + (C a)) ∣ (X ^ 13 + X + (C 90)) ↔ a = putnam_1963_b1_solution := by
  intro a
  constructor
  · intro h
    -- Evaluating the divisibility at `0` and `1` pins `a` down to a divisor of `2`.
    have d0 := Polynomial.eval_dvd (x := (0 : ℤ)) h
    have d1 := Polynomial.eval_dvd (x := (1 : ℤ)) h
    simp only [eval_add, eval_sub, eval_pow, eval_X, eval_C] at d0 d1
    norm_num at d0 d1
    have hd2 : a ∣ 2 := by
      have := dvd_sub d1 d0
      norm_num at this
      exact this
    have hub : a ≤ 2 := Int.le_of_dvd (by norm_num) hd2
    have hlb : -2 ≤ a := by
      have h' : -a ∣ 2 := (neg_dvd).mpr hd2
      have := Int.le_of_dvd (by norm_num) h'
      linarith
    interval_cases a
    · -- a = -2
      have d := Polynomial.eval_dvd (x := (4 : ℤ)) h
      norm_num [eval_add, eval_sub, eval_pow, eval_X, eval_C] at d
    · -- a = -1
      have d := Polynomial.eval_dvd (x := (3 : ℤ)) h
      norm_num [eval_add, eval_sub, eval_pow, eval_X, eval_C] at d
    · -- a = 0
      have d := Polynomial.eval_dvd (x := (0 : ℤ)) h
      norm_num [eval_add, eval_sub, eval_pow, eval_X, eval_C] at d
    · -- a = 1
      have d := Polynomial.eval_dvd (x := (2 : ℤ)) h
      norm_num [eval_add, eval_sub, eval_pow, eval_X, eval_C] at d
    · -- a = 2
      rfl
  · intro h
    subst h
    refine ⟨X^11 + X^10 - X^9 - 3*X^8 - X^7 + 5*X^6 + 7*X^5 - 3*X^4
              - 17*X^3 - 11*X^2 + 23*X + 45, ?_⟩
    simp only [map_ofNat]
    ring
