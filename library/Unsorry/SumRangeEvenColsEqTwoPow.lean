import Mathlib

open Finset

theorem sum_range_even_cols_eq_two_pow (n : ℕ) (hn : 1 ≤ n) : ∑ k ∈ Finset.range (n + 1), (2 * n).choose (2 * k) = 2 ^ (2 * n - 1) := by
  have h2n : (2 * n) ≠ 0 := by positivity
  have hS : (∑ j ∈ range (2 * n + 1), ((2 * n).choose j : ℤ)) = 2 ^ (2 * n) := by
    have h := Nat.sum_range_choose (2 * n)
    exact_mod_cast h
  have hA : (∑ j ∈ range (2 * n + 1), ((-1) ^ j * (2 * n).choose j : ℤ)) = 0 := by
    rw [Int.alternating_sum_range_choose_of_ne h2n]
  have hsum : (∑ j ∈ range (2 * n + 1), ((1 + (-1) ^ j) * (2 * n).choose j : ℤ)) = 2 ^ (2 * n) := by
    have hsplit : (∑ j ∈ range (2 * n + 1), ((1 + (-1) ^ j) * (2 * n).choose j : ℤ))
        = (∑ j ∈ range (2 * n + 1), ((2 * n).choose j : ℤ))
          + (∑ j ∈ range (2 * n + 1), ((-1) ^ j * (2 * n).choose j : ℤ)) := by
      rw [← Finset.sum_add_distrib]
      apply Finset.sum_congr rfl
      intro j _
      ring
    rw [hsplit, hS, hA, add_zero]
  have key : (∑ j ∈ range (2 * n + 1), ((1 + (-1) ^ j) * (2 * n).choose j : ℤ))
      = 2 * (∑ k ∈ range (n + 1), ((2 * n).choose (2 * k) : ℤ)) := by
    rw [← Finset.sum_filter_add_sum_filter_not (range (2 * n + 1)) (fun j => Even j)]
    have hodd : (∑ j ∈ (range (2 * n + 1)).filter (fun j => ¬ Even j),
        ((1 + (-1) ^ j) * (2 * n).choose j : ℤ)) = 0 := by
      apply Finset.sum_eq_zero
      intro j hj
      rw [Finset.mem_filter] at hj
      have hjodd : Odd j := Nat.not_even_iff_odd.mp hj.2
      rw [Odd.neg_one_pow hjodd]
      ring
    rw [hodd, add_zero, Finset.mul_sum]
    apply Finset.sum_nbij' (fun j => j / 2) (fun k => 2 * k)
    · intro j hj
      rw [Finset.mem_filter] at hj
      obtain ⟨hjmem, hjeven⟩ := hj
      rw [Finset.mem_range] at hjmem ⊢
      omega
    · intro k hk
      rw [Finset.mem_range] at hk
      rw [Finset.mem_filter, Finset.mem_range]
      exact ⟨by omega, ⟨k, by ring⟩⟩
    · intro j hj
      rw [Finset.mem_filter] at hj
      obtain ⟨_, c, rfl⟩ := hj
      omega
    · intro k _
      omega
    · intro j hj
      rw [Finset.mem_filter] at hj
      obtain ⟨_, c, rfl⟩ := hj
      have hd : (c + c) / 2 = c := by omega
      rw [hd]
      have hev : Even (c + c) := ⟨c, rfl⟩
      rw [Even.neg_one_pow hev]
      have h2c : (2 : ℕ) * c = c + c := by ring
      rw [h2c]
      ring
  have hZ : (2 : ℤ) * (∑ k ∈ range (n + 1), ((2 * n).choose (2 * k) : ℤ)) = 2 ^ (2 * n) := by
    rw [← key, hsum]
  have hpow : (2 : ℤ) ^ (2 * n) = 2 * 2 ^ (2 * n - 1) := by
    have he : 2 * n = 2 * n - 1 + 1 := by omega
    conv_lhs => rw [he]
    rw [pow_succ']
  rw [hpow] at hZ
  have hcancel := mul_left_cancel₀ (by norm_num : (2 : ℤ) ≠ 0) hZ
  have hgoal : ((∑ k ∈ range (n + 1), (2 * n).choose (2 * k) : ℕ) : ℤ)
      = ((2 ^ (2 * n - 1) : ℕ) : ℤ) := by
    push_cast
    rw [hcancel]
  exact_mod_cast hgoal