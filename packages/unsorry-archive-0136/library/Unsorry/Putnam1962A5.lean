import Mathlib

/-!
# Putnam 1962 A5

The closed form `n * (n + 1) * 2 ^ (n - 2)` for the weighted binomial sum
`∑ k ∈ Finset.Icc 1 n, Nat.choose n k * k ^ 2`, valid for `n ≥ 2`.

The core identity, in a subtraction-free shape that holds for every `n`, is
`4 * (∑ i ∈ range (n + 1), i ^ 2 * n.choose i) = n * (n + 1) * 2 ^ n`,
proved by induction via the Pascal recurrence and the standard sums
`∑ i, n.choose i = 2 ^ n` and `∑ i, i * n.choose i = n * 2 ^ (n - 1)`.
-/

namespace Putnam1962A5Aux

open Finset

/-- Reindexing identity: shifting the quadratic-weighted sum's index by one and the
upper binomial argument by one recovers the original sum (the boundary terms vanish). -/
private lemma shift_eq (n : ℕ) :
    (∑ i ∈ range (n + 1), (i + 1) ^ 2 * n.choose (i + 1))
      = ∑ i ∈ range (n + 1), i ^ 2 * n.choose i := by
  have h1 : (∑ i ∈ range (n + 2), i ^ 2 * n.choose i)
      = ∑ i ∈ range (n + 1), (i + 1) ^ 2 * n.choose (i + 1) := by
    rw [Finset.sum_range_succ']
    simp
  have h2 : (∑ i ∈ range (n + 2), i ^ 2 * n.choose i)
      = ∑ i ∈ range (n + 1), i ^ 2 * n.choose i := by
    rw [Finset.sum_range_succ, Nat.choose_succ_self]
    ring
  rw [← h1, h2]

/-- The Pascal-rule split of the quadratic-weighted binomial sum at `n + 1` into the
quadratic, linear, and plain weighted sums at `n`. -/
private lemma split (n : ℕ) :
    (∑ i ∈ range (n + 2), i ^ 2 * (n + 1).choose i)
      = 2 * (∑ i ∈ range (n + 1), i ^ 2 * n.choose i)
        + 2 * (∑ i ∈ range (n + 1), i * n.choose i)
        + ∑ i ∈ range (n + 1), n.choose i := by
  rw [Finset.sum_range_succ']
  have hexpand : ∀ i ∈ range (n + 1),
      (i + 1) ^ 2 * (n + 1).choose (i + 1)
        = (i ^ 2 * n.choose i + 2 * (i * n.choose i) + n.choose i)
          + (i + 1) ^ 2 * n.choose (i + 1) := by
    intro i _
    rw [Nat.choose_succ_succ' n i]
    ring
  rw [Finset.sum_congr rfl hexpand, Finset.sum_add_distrib, Finset.sum_add_distrib,
    Finset.sum_add_distrib, ← Finset.mul_sum, shift_eq n]
  ring

/-- The core subtraction-free identity, proved by induction on `n`. -/
private lemma core (n : ℕ) :
    4 * (∑ i ∈ range (n + 1), i ^ 2 * n.choose i) = n * (n + 1) * 2 ^ n := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [split n]
    have hB : (∑ i ∈ range (n + 1), n.choose i) = 2 ^ n := Nat.sum_range_choose n
    have hS : 2 * (∑ i ∈ range (n + 1), i * n.choose i) = n * 2 ^ n := by
      rw [Nat.sum_range_mul_choose]
      cases n with
      | zero => simp
      | succ m => simp only [Nat.add_sub_cancel, pow_succ]; ring
    rw [hS, hB]
    calc 4 * (2 * (∑ i ∈ range (n + 1), i ^ 2 * n.choose i) + n * 2 ^ n + 2 ^ n)
        = 2 * (4 * (∑ i ∈ range (n + 1), i ^ 2 * n.choose i))
          + 4 * (n * 2 ^ n) + 4 * 2 ^ n := by ring
      _ = 2 * (n * (n + 1) * 2 ^ n) + 4 * (n * 2 ^ n) + 4 * 2 ^ n := by rw [ih]
      _ = (n + 1) * (n + 1 + 1) * 2 ^ (n + 1) := by rw [pow_succ]; ring

end Putnam1962A5Aux

open Finset in
/-- Convert the target `Finset.Icc 1 n` sum into the `Finset.range (n + 1)` form used by
the core identity, dropping the vanishing `k = 0` term and commuting the factors. -/
private lemma putnam_1962_a5_sum_eq (n : ℕ) :
    (∑ k ∈ Finset.Icc 1 n, Nat.choose n k * k ^ 2)
      = ∑ i ∈ Finset.range (n + 1), i ^ 2 * n.choose i := by
  have hsub : Finset.Icc 1 n ⊆ Finset.range (n + 1) := by
    intro x hx
    rw [Finset.mem_Icc] at hx
    rw [Finset.mem_range]
    omega
  have hz : ∀ x ∈ Finset.range (n + 1), x ∉ Finset.Icc 1 n →
      Nat.choose n x * x ^ 2 = 0 := by
    intro x hx hxs
    rw [Finset.mem_range] at hx
    rw [Finset.mem_Icc] at hxs
    have hx0 : x = 0 := by omega
    subst hx0
    simp
  rw [Finset.sum_subset hsub hz]
  apply Finset.sum_congr rfl
  intro k _
  ring

abbrev putnam_1962_a5_solution : ℕ → ℕ := fun n : ℕ => n * (n + 1) * 2 ^ (n - 2)

theorem putnam_1962_a5 : ∀ n ≥ 2, putnam_1962_a5_solution n = ∑ k ∈ Finset.Icc 1 n, Nat.choose n k * k^2 := by
  intro n hn
  show n * (n + 1) * 2 ^ (n - 2) = ∑ k ∈ Finset.Icc 1 n, Nat.choose n k * k ^ 2
  rw [putnam_1962_a5_sum_eq n]
  have hpow : (2 : ℕ) ^ n = 2 ^ (n - 2) * 4 := by
    conv_lhs => rw [show n = (n - 2) + 2 from by omega]
    rw [pow_add]
    norm_num
  have hcancel : 4 * (∑ i ∈ Finset.range (n + 1), i ^ 2 * n.choose i)
      = 4 * (n * (n + 1) * 2 ^ (n - 2)) := by
    rw [Putnam1962A5Aux.core n, hpow]
    ring
  exact (Nat.eq_of_mul_eq_mul_left (by norm_num) hcancel).symm
