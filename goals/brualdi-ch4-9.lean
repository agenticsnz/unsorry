import Mathlib

def invNum {n : ℕ} (σ : Equiv.Perm (Fin n)) : ℕ :=
  ∑ x ∈ Equiv.Perm.finPairsLT n, if σ x.fst ≤ σ x.snd then 1 else 0

theorem brualdi_ch4_9 (n : ℕ) :
    IsGreatest {k | ∃ σ : Equiv.Perm (Fin n), k = invNum σ} (n * (n - 1) / 2) := by
  sorry
