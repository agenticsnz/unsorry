import Mathlib

def appears (W : ℤ → Fin 2) (U : Σ n, Fin n → Fin 2) : Prop :=
  ∃ k, ∀ i : Fin U.1, U.2 i = W (k + i)
def ubiquitous (W : ℤ → Fin 2) (U : Σ n, Fin n → Fin 2) : Prop :=
  appears W ⟨U.1 + 1, Fin.snoc U.2 0⟩ ∧
  appears W ⟨U.1 + 1, Fin.snoc U.2 1⟩ ∧
  appears W ⟨U.1 + 1, Fin.cons 0 U.2⟩ ∧
  appears W ⟨U.1 + 1, Fin.cons 1 U.2⟩

theorem imosl_2011_c6 (W : ℤ → Fin 2) (n : ℕ+) (N : ℕ) (hN : 2 ^ n.1 < N)
    (hW : Function.Periodic W N) (hW' : ∀ N', 0 < N' ∧ N' < N → ¬ Function.Periodic W N') :
    ∃ (x : Fin n ↪ (Σ k, Fin k → Fin 2)), (∀ i, (x i).1 ≠ 0) ∧ (∀ i, ubiquitous W (x i)) := by
  sorry
