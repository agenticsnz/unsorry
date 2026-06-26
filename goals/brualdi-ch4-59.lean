import Mathlib

def invNum {n : ℕ} (σ : Equiv.Perm (Fin n)) : ℕ :=
  ∑ x ∈ Equiv.Perm.finPairsLT n, if σ x.fst ≤ σ x.snd then 1 else 0

theorem brualdi_ch4_59 (n : ℕ) (hn : n ≥ 2) : ∑ σ : Equiv.Perm (Fin n), invNum σ =
    n.factorial * n * (n - 1) / 4 := by
  sorry
