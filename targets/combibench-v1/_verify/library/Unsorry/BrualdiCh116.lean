import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.LinearAlgebra.Matrix.Defs
import Mathlib.Order.Interval.Finset.Nat

/-!
# Brualdi, Chapter 1, Exercise 16

Replacing each entry `M i j` of an `n × n` magic square `M` by `n ^ 2 + 1 - M i j` produces
another magic square:
- Since `1 ≤ M i j ≤ n ^ 2`, each transformed entry still lies in `Finset.Icc 1 (n * n)`.
- Subtracting bounded naturals from `n ^ 2 + 1` is injective, preserving distinctness of entries.
- Adding any row, column, or main/antidiagonal sum of `replace M` to the corresponding sum `s` of
  `M` yields `n * (n ^ 2 + 1)`, so every such sum in `replace M` equals `n * (n ^ 2 + 1) - s`.
-/

structure IsMagicSquare {n : ℕ} (M : Matrix (Fin n) (Fin n) ℕ) : Prop where
  mem : ∀ i j, M i j ∈ Finset.Icc 1 (n * n)
  pairwise : ∀ i j i' j', i ≠ i' ∨ j ≠ j' → M i j ≠ M i' j'
  same_sum : ∃ s, (∀ i, ∑ j, M i j = s) ∧ (∀ j, ∑ i, M i j = s) ∧ (∑ i, M i i.rev = s) ∧ ∑ i, M i i = s
abbrev replace {n : ℕ}: Matrix (Fin n) (Fin n) ℕ → Matrix (Fin n) (Fin n) ℕ :=
  fun A i j ↦ n^2 + 1 - A i j

theorem brualdi_ch1_16 {n : ℕ} (M : Matrix (Fin n) (Fin n) ℕ) (hM : IsMagicSquare M) :
    IsMagicSquare (replace M) := by
  have hsq : n ^ 2 = n * n := Nat.pow_two n
  have hmem : ∀ i j, 1 ≤ M i j ∧ M i j ≤ n * n := fun i j ↦ Finset.mem_Icc.mp (hM.mem i j)
  refine ⟨?_, ?_, ?_⟩
  · intro i j
    rw [Finset.mem_Icc]
    have := hmem i j
    dsimp [replace]
    omega
  · intro i j i' j' hne
    have := hmem i j
    have := hmem i' j'
    have := hM.pairwise i j i' j' hne
    dsimp [replace]
    omega
  · rcases hM.same_sum with ⟨s, hrow, hcol, hanti, hdiag⟩
    have hle : ∀ i j, M i j ≤ n ^ 2 + 1 := fun i j ↦ by
      have := hmem i j
      omega
    have sum_sub : ∀ f : Fin n → ℕ, (∀ k, f k ≤ n ^ 2 + 1) → ∑ k, f k = s →
        ∑ k, (n ^ 2 + 1 - f k) = n * (n ^ 2 + 1) - s := by
      intro f hfk hsum
      have hadd : (∑ k, (n ^ 2 + 1 - f k)) + ∑ k, f k = n * (n ^ 2 + 1) := by
        rw [← Finset.sum_add_distrib,
          Finset.sum_const_nat (fun k _ ↦ Nat.sub_add_cancel (hfk k)), Finset.card_fin]
      omega
    exact ⟨n * (n ^ 2 + 1) - s,
      fun i ↦ sum_sub (M i) (hle i) (hrow i),
      fun j ↦ sum_sub (M · j) (hle · j) (hcol j),
      sum_sub (fun i ↦ M i i.rev) (fun i ↦ hle i i.rev) hanti,
      sum_sub (fun i ↦ M i i) (fun i ↦ hle i i) hdiag⟩
