import Mathlib.Algebra.BigOperators.Group.Finset.Defs
import Mathlib.LinearAlgebra.Matrix.Defs
import Mathlib.Order.Interval.Finset.Nat

/-!
# Nonexistence of 2-by-2 Magic Squares

We prove Brualdi, Chapter 1, Problem 10: there is no `2 × 2` magic square.
If `M` has common row and column sum `s`, equating the first row sum `M 0 0 + M 0 1 = s`
with the first column sum `M 0 0 + M 1 0 = s` forces `M 0 1 = M 1 0`, contradicting
pairwise distinctness of the entries at `(0, 1)` and `(1, 0)`.
-/

structure IsMagicSquare {n : ℕ} (M : Matrix (Fin n) (Fin n) ℕ) : Prop where
  mem : ∀ i j, M i j ∈ Finset.Icc 1 (n * n)
  pairwise : ∀ i j i' j', i ≠ i' ∨ j ≠ j' → M i j ≠ M i' j'
  same_sum : ∃ s, (∀ i, ∑ j, M i j = s) ∧ (∀ j, ∑ i, M i j = s) ∧ (∑ i, M i i.rev = s) ∧ ∑ i, M i i = s

theorem brualdi_ch1_10 : ¬∃ (M : Matrix (Fin 2) (Fin 2) ℕ), IsMagicSquare M := by
  rintro ⟨M, hM⟩
  obtain ⟨s, hrow, hcol, -, -⟩ := hM.same_sum
  have hr0 : M 0 0 + (M 0 1 + 0) = s := hrow 0
  have hc0 : M 0 0 + (M 1 0 + 0) = s := hcol 0
  have heq : M 0 1 = M 1 0 := by omega
  exact hM.pairwise 0 1 1 0 (Or.inl (by decide)) heq
