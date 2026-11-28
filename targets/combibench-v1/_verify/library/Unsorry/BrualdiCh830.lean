import Mathlib.Combinatorics.Enumerative.Partition
import Mathlib.Data.Fintype.Card

/-!
Adding a part of size one injects the partitions of `n - 1` into those of `n`.
For `n ≥ 2`, the partition with a single part of size `n` is outside the image.
-/

theorem brualdi_ch8_30 (n : ℕ) (hn : 2 ≤ n) :
    Fintype.card (Nat.Partition (n - 1)) < Fintype.card (Nat.Partition n) := by
  let f : Nat.Partition (n - 1) → Nat.Partition n := fun p =>
    { parts := 1 ::ₘ p.parts
      parts_pos := by
        intro i hi
        rcases Multiset.mem_cons.mp hi with h | h
        · subst i
          exact Nat.zero_lt_one
        · exact p.parts_pos h
      parts_sum := by
        rw [Multiset.sum_cons, p.parts_sum]
        omega }
  have hf : Function.Injective f := by
    intro p q h
    apply Nat.Partition.ext
    have hparts := congrArg Nat.Partition.parts h
    exact (Multiset.cons_inj_right 1).mp hparts
  apply Fintype.card_lt_of_injective_of_notMem f hf
    (b := Nat.Partition.indiscrete n)
  rintro ⟨p, hp⟩
  have hmem : 1 ∈ (f p).parts := Multiset.mem_cons_self _ _
  rw [hp, Nat.Partition.indiscrete_parts (by omega)] at hmem
  have h : 1 = n := Multiset.mem_singleton.mp hmem
  omega
