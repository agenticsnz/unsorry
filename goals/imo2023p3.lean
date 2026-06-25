import Mathlib

open scoped Polynomial
def answer : Set.Ici 2 → Set (ℕ → ℕ) := sorry

theorem imo2023p3 : (fun (k : Set.Ici 2) ↦ {a : ℕ → ℕ |
    (∀ i, 0 < a i) ∧ ∃ P : ℕ[X], P.Monic ∧ P.degree = k ∧
    ∀ n, P.eval (a n) = ∏ i ∈ Finset.Icc (n + 1) (n + ↑k), a i}) = answer := by
  sorry
