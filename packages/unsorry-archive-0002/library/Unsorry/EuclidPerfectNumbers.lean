import Lean.Linter.UnusedVariables
import Mathlib.NumberTheory.Divisors
import Unsorry.EuclidPerfectNumbersS1
import Unsorry.EuclidPerfectNumbersS2
import Unsorry.EuclidPerfectNumbersS3
import Unsorry.EuclidPerfectNumbersS4
import Unsorry.EuclidPerfectNumbersS5
import Unsorry.EuclidPerfectNumbersS6

/-!
# Euclid's perfect-number theorem (goal `euclid-perfect-numbers`)

If `2 ^ p - 1` is prime then `2 ^ (p - 1) * (2 ^ p - 1)` is perfect — the
"if" direction of the Euclid–Euler characterisation of even perfect numbers.

A positive `n` is perfect exactly when the sum of all its divisors is `2 * n`
(`Nat.perfect_iff_sum_divisors_eq_two_mul`), so it suffices to compute that
sum. The two factors `2 ^ (p - 1)` and `2 ^ p - 1` are coprime
(`coprime_two_pow_mersenne`), so the divisor-sum is multiplicative across them
(`sum_divisors_mul_of_coprime`). The first factor contributes
`2 ^ (p - 1 + 1) - 1` (`sum_divisors_two_pow`) and the prime second factor
contributes `(2 ^ p - 1) + 1` (`sum_divisors_eq_succ_of_prime`); these multiply
to `2 * (2 ^ (p - 1) * (2 ^ p - 1))` (`two_pow_pred_mersenne_arith`, valid once
`mersenne_prime_one_le_exp` supplies `1 ≤ p`). Each step is a kernel-verified
sub-lemma of this goal family (ADR-014).
-/

theorem perfect_of_mersenne_prime (p : ℕ) (hp : Nat.Prime (2 ^ p - 1)) :
    Nat.Perfect (2 ^ (p - 1) * (2 ^ p - 1)) := by
  have hp1 : 1 ≤ p := mersenne_prime_one_le_exp p hp
  have hqpos : 0 < 2 ^ p - 1 := by have := hp.two_le; omega
  have hpos : 0 < 2 ^ (p - 1) * (2 ^ p - 1) := Nat.mul_pos (by positivity) hqpos
  rw [Nat.perfect_iff_sum_divisors_eq_two_mul hpos,
    sum_divisors_mul_of_coprime _ _ (coprime_two_pow_mersenne p),
    sum_divisors_two_pow (p - 1), sum_divisors_eq_succ_of_prime _ hp]
  exact two_pow_pred_mersenne_arith p hp1

/-- The ADR-011 binding obligation that Gate A regenerates for this goal states
its type as `∀ (p : ℕ) (hp : Nat.Prime (2 ^ p - 1)), Nat.Perfect …`, copying the
goal's binder names verbatim. `hp` does not occur in the conclusion, so the
unused-variables linter warns on it and the `--wfail` bar fails — in a generated
file this module cannot edit. Core Lean already exempts unused binders in the
arrow spelling `(h : P) → Q` of the same type (its builtin `depArrow` ignore
function), because a binder name there is signature documentation; this extends
that exemption to the `∀ (h : P), Q` spelling. Lint-scope only: it has no effect
on elaboration or the kernel check. -/
@[unused_variables_ignore_fn]
def Unsorry.EuclidPerfectNumbers.ignoreForallTypeBinders :
    Lean.Linter.IgnoreFunction := fun _ stack _ =>
  stack.matches [`null, ``Lean.Parser.Term.explicitBinder, `null,
    ``Lean.Parser.Term.«forall»]
