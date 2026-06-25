import Mathlib

theorem brualdi_ch9_13 (n m k : ℕ) (r : ℕ → ℕ) (A : Matrix (Fin m) (Fin n) ℕ)
    (hn : n > 0) (hm : m > 0)(hk : k ≥ 1)
    (hA : ∀ i j, A i j ∈ Finset.Icc 1 k)
    (hr : ∀ i ∈ Finset.Icc 1 k, (∑ x : Fin m, ∑ y : Fin n, if A x y = i then 1 else 0) = n * r i) :
    ∃ (rσ : Fin m → Equiv.Perm (Fin n)),
      ∀ j : Fin n, ∀ i ∈ Finset.Icc 1 k,
      (∑ x : Fin m, if A x ((rσ x) j) = i then 1 else 0) = r i := by
  sorry
