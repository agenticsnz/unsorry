import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Data.Fintype.BigOperators
import Mathlib.GroupTheory.Perm.Sign

/-!
Each pair contributes at most one, and the reverse permutation makes every pair
contribute one. Counting the pairs gives the sum of the integers below `n`.
-/

def invNum {n : ℕ} (σ : Equiv.Perm (Fin n)) : ℕ :=
  ∑ x ∈ Equiv.Perm.finPairsLT n, if σ x.fst ≤ σ x.snd then 1 else 0

theorem brualdi_ch4_9 (n : ℕ) :
    IsGreatest {k | ∃ σ : Equiv.Perm (Fin n), k = invNum σ} (n * (n - 1) / 2) := by
  have hcard : (Equiv.Perm.finPairsLT n).card = n * (n - 1) / 2 := by
    simp only [Equiv.Perm.finPairsLT, Finset.card_sigma, Finset.card_attachFin,
      Finset.card_range]
    exact (Fin.sum_univ_eq_sum_range (fun i : ℕ => i) n).trans (Finset.sum_range_id n)
  constructor
  · refine ⟨Fin.revPerm, ?_⟩
    rw [← hcard, invNum]
    symm
    calc
      _ = ∑ _x ∈ Equiv.Perm.finPairsLT n, (1 : ℕ) := by
        apply Finset.sum_congr rfl
        intro x hx
        have hle : Fin.revPerm x.fst ≤ Fin.revPerm x.snd :=
          Fin.rev_le_rev.mpr (Equiv.Perm.mem_finPairsLT.mp hx).le
        exact if_pos hle
      _ = _ := by simp
  · rintro k ⟨σ, rfl⟩
    rw [← hcard, invNum]
    calc
      _ ≤ ∑ _x ∈ Equiv.Perm.finPairsLT n, (1 : ℕ) := by
        apply Finset.sum_le_sum
        intro x _
        split <;> simp
      _ = _ := by simp
