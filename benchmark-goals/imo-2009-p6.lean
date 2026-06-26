import Mathlib

open BigOperators Finset

theorem imo_2009_p6 (n : ℕ) (hn : n ≥ 1) (a : Fin n → ℕ) (ha : Function.Injective a) (M : Finset ℕ)
    (ha' : ∀ i, a i > 0) (hM : M.card = n - 1) (hM' : ∀ m ∈ M, m > 0) (haM : ∑ n, (a n) ∉ M) :
    ∃ (σ : Equiv.Perm (Fin n)), ∀ k, (∑ i ≤ k, (a ∘ σ) i) ∉ M := by
  sorry
