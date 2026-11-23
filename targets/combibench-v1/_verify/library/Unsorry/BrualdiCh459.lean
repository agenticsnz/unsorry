import Mathlib.GroupTheory.Perm.Sign

/-!
# Total Number of Inversions Across All Permutations (Brualdi, Chapter 4, Problem 59)

We compute the sum of inversion counts `invNum σ` over all permutations `σ` of `Fin n` (`n ≥ 2`).
Pairing each permutation `σ` with `Fin.revPerm * σ` reverses all relative output orders, so
`invNum σ + invNum (Fin.revPerm * σ)` equals the cardinality of `Equiv.Perm.finPairsLT n`,
namely `∑ a : Fin n, (a : ℕ)`. Applying the reversal involution `Fin.revPerm` once more shows
`2 * (Equiv.Perm.finPairsLT n).card = n * (n - 1)`, yielding
`4 * ∑ σ, invNum σ = n.factorial * n * (n - 1)` and hence the result.
-/

def invNum {n : ℕ} (σ : Equiv.Perm (Fin n)) : ℕ :=
  ∑ x ∈ Equiv.Perm.finPairsLT n, if σ x.fst ≤ σ x.snd then 1 else 0

private theorem invNum_add_revPerm {n : ℕ} (σ : Equiv.Perm (Fin n)) :
    invNum σ + invNum (Fin.revPerm * σ) = (Equiv.Perm.finPairsLT n).card := by
  unfold invNum
  rw [← Finset.sum_add_distrib, Finset.card_eq_sum_ones]
  refine Finset.sum_congr rfl fun x hx ↦ ?_
  have hne : σ x.fst ≠ σ x.snd := σ.injective.ne (Equiv.Perm.mem_finPairsLT.mp hx).ne'
  simp only [Equiv.Perm.mul_apply, Fin.revPerm_apply, Fin.rev_le_rev]
  by_cases h : σ x.fst ≤ σ x.snd
  · have h' : ¬ σ x.snd ≤ σ x.fst := fun hle ↦ hne (le_antisymm h hle)
    simp [h, h']
  · have h' : σ x.snd ≤ σ x.fst := le_of_not_ge h
    simp [h, h']

private theorem card_finPairsLT_mul_two (n : ℕ) :
    2 * (Equiv.Perm.finPairsLT n).card = n * (n - 1) := by
  have hcard : (Equiv.Perm.finPairsLT n).card = ∑ a : Fin n, (a : ℕ) := by
    unfold Equiv.Perm.finPairsLT
    exact (Multiset.card_sigma Finset.univ.val _).trans
      (Finset.sum_congr rfl fun a _ ↦ (Finset.card_attachFin _ _).trans (Finset.card_range _))
  rw [hcard, Nat.two_mul]
  conv_lhs => rhs; rw [← Equiv.sum_comp Fin.revPerm (fun a : Fin n ↦ (a : ℕ))]
  rw [← Finset.sum_add_distrib]
  have hsum : ∀ a : Fin n, (a : ℕ) + ((Fin.revPerm a : Fin n) : ℕ) = n - 1 := fun a ↦ by
    rw [Fin.revPerm_apply, Fin.val_rev]
    omega
  simp_rw [hsum]
  simp

theorem brualdi_ch4_59 (n : ℕ) (hn : n ≥ 2) : ∑ σ : Equiv.Perm (Fin n), invNum σ =
    n.factorial * n * (n - 1) / 4 := by
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 2 := ⟨n - 2, (Nat.sub_add_cancel hn).symm⟩
  have hsum : 2 * ∑ σ : Equiv.Perm (Fin (m + 2)), invNum σ =
      (m + 2).factorial * (Equiv.Perm.finPairsLT (m + 2)).card := by
    rw [Nat.two_mul]
    conv_lhs => rhs; rw [← Equiv.sum_comp (Equiv.mulLeft Fin.revPerm) invNum]
    rw [← Finset.sum_add_distrib]
    simp [Equiv.mulLeft, invNum_add_revPerm, Fintype.card_perm]
  have h4 : 4 * ∑ σ : Equiv.Perm (Fin (m + 2)), invNum σ =
      (m + 2).factorial * (m + 2) * (m + 2 - 1) := by
    calc 4 * ∑ σ : Equiv.Perm (Fin (m + 2)), invNum σ
        = 2 * (2 * ∑ σ : Equiv.Perm (Fin (m + 2)), invNum σ) := by omega
      _ = 2 * ((m + 2).factorial * (Equiv.Perm.finPairsLT (m + 2)).card) := by rw [hsum]
      _ = (m + 2).factorial * (2 * (Equiv.Perm.finPairsLT (m + 2)).card) := by
          rw [← Nat.mul_assoc, Nat.mul_comm 2, Nat.mul_assoc]
      _ = (m + 2).factorial * ((m + 2) * (m + 2 - 1)) := by rw [card_finPairsLT_mul_two]
      _ = (m + 2).factorial * (m + 2) * (m + 2 - 1) := (Nat.mul_assoc _ _ _).symm
  omega
