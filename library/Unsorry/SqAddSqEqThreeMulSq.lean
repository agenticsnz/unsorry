import Unsorry.SqAddSqEqThreeMulSqS2

/-!
# `sq_add_sq_eq_three_mul_sq`

The Diophantine equation `x ^ 2 + y ^ 2 = 3 * z ^ 2` has only the trivial
solution `x = y = z = 0` in the integers.

The proof is Fermat's infinite descent on `|x| + |y| + |z|`, by strong
induction. It reuses the proved library lemma
`three_dvd_all_of_sq_add_sq_eq_three_mul_sq` (goal
`sq-add-sq-eq-three-mul-sq-s2`): every coordinate of a solution is divisible by
`3`. Writing `x = 3a`, `y = 3b`, `z = 3c` and cancelling `9` shows that
`(a, b, c)` is again a solution, with coordinate sum one third of the original.
If that sum is `0` the triple is zero; otherwise it is strictly smaller, and
the induction hypothesis makes `(a, b, c)` zero, hence `(x, y, z)` too.

This closes the goal directly instead of through its recorded decomposition.
The sub-goal `sq-add-sq-eq-three-mul-sq-s4` (and its descendants `-s4-s3`,
`-s4-s3-s2`) is false as stated: a descent hypothesis that only promises a
smaller triple, possibly the zero triple, does not force every triple to be
zero (take `P` true exactly at `(1, 0, 0)` and `(0, 0, 0)`). The descent here
keeps the hypothesis that matters, divisibility of all three coordinates.
-/

theorem sq_add_sq_eq_three_mul_sq (x y z : ℤ) (h : x^2 + y^2 = 3 * z^2) :
    x = 0 ∧ y = 0 ∧ z = 0 := by
  -- Strong induction on `n = |x| + |y| + |z|`.
  suffices key : ∀ n : ℕ, ∀ x y z : ℤ, x.natAbs + y.natAbs + z.natAbs = n →
      x ^ 2 + y ^ 2 = 3 * z ^ 2 → x = 0 ∧ y = 0 ∧ z = 0 from
    key _ x y z rfl h
  intro n
  induction n using Nat.strong_induction_on with
  | _ n ih =>
    intro x y z hn hxyz
    -- Every coordinate of a solution is divisible by `3`.
    obtain ⟨⟨a, rfl⟩, ⟨b, rfl⟩, ⟨c, rfl⟩⟩ :=
      three_dvd_all_of_sq_add_sq_eq_three_mul_sq x y z hxyz
    -- Cancelling `9` shows that `(a, b, c)` is again a solution.
    have habc : a ^ 2 + b ^ 2 = 3 * c ^ 2 := by
      have e : (9 : ℤ) * (a ^ 2 + b ^ 2) = 9 * (3 * c ^ 2) := by
        linear_combination hxyz
      exact mul_left_cancel₀ (by omega : (9 : ℤ) ≠ 0) e
    by_cases h0 : a.natAbs + b.natAbs + c.natAbs = 0
    · -- The reduced triple is zero, so the original one is too.
      omega
    · -- Otherwise the reduced triple is strictly smaller: descend.
      obtain ⟨ha, hb, hc⟩ :=
        ih (a.natAbs + b.natAbs + c.natAbs) (by omega) a b c rfl habc
      omega
