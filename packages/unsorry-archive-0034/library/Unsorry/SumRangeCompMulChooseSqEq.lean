import Mathlib

open Finset
theorem sum_range_comp_mul_choose_sq_eq (n : ℕ) : ∑ k ∈ Finset.range (n + 2), ((n : ℤ) + 1 - k) * (((n + 1).choose k : ℕ) : ℤ) ^ 2 = ((n : ℤ) + 1) * ((2 * n + 2).choose (n + 1) : ℕ) - ((n : ℤ) + 1) * ((2 * n + 1).choose n : ℕ) := by
  -- abbreviations
  set L : ℤ := ∑ k ∈ Finset.range (n + 2), ((n : ℤ) + 1 - k) * (((n + 1).choose k : ℕ) : ℤ) ^ 2 with hL
  -- the "k-weighted" sum
  set S : ℤ := ∑ k ∈ Finset.range (n + 2), (k : ℤ) * (((n + 1).choose k : ℕ) : ℤ) ^ 2 with hS
  -- By reflection k ↦ (n+1)-k, L = S
  have hLS : L = S := by
    rw [hL, hS]
    rw [show n + 2 = (n + 1) + 1 by ring]
    rw [← Finset.sum_range_reflect (fun k => ((n : ℤ) + 1 - k) * (((n + 1).choose k : ℕ) : ℤ) ^ 2) (n + 1 + 1)]
    apply Finset.sum_congr rfl
    intro k hk
    rw [Finset.mem_range] at hk
    -- index becomes n+1+1-1-k = n+1-k
    have hk' : k ≤ n + 1 := by omega
    have hsymm : ((n + 1).choose (n + 1 + 1 - 1 - k) : ℕ) = ((n + 1).choose k : ℕ) := by
      rw [show n + 1 + 1 - 1 - k = (n + 1) - k by omega]
      exact Nat.choose_symm hk'
    rw [hsymm]
    have : ((n : ℤ) + 1 - ↑(n + 1 + 1 - 1 - k)) = (k : ℤ) := by
      have : (n + 1 + 1 - 1 - k : ℕ) = (n + 1) - k := by omega
      rw [this]
      push_cast [Nat.cast_sub hk']
      ring
    rw [this]
  -- L + S = (n+1) * binom(2n+2, n+1)
  have hLpS : L + S = ((n : ℤ) + 1) * ((2 * n + 2).choose (n + 1) : ℕ) := by
    rw [hL, hS, ← Finset.sum_add_distrib]
    have hsum : ∑ k ∈ Finset.range (n + 2),
        (((n : ℤ) + 1 - k) * (((n + 1).choose k : ℕ) : ℤ) ^ 2
          + (k : ℤ) * (((n + 1).choose k : ℕ) : ℤ) ^ 2)
        = ∑ k ∈ Finset.range (n + 2), ((n : ℤ) + 1) * (((n + 1).choose k : ℕ) : ℤ) ^ 2 := by
      apply Finset.sum_congr rfl
      intro k _
      ring
    rw [hsum, ← Finset.mul_sum]
    congr 1
    -- ∑ binom(n+1,k)^2 = binom(2(n+1), n+1)
    have key : ∑ k ∈ Finset.range (n + 2), (((n + 1).choose k : ℕ) : ℤ) ^ 2
        = (((2 * (n + 1)).choose (n + 1) : ℕ) : ℤ) := by
      have := Nat.sum_range_choose_sq (n + 1)
      rw [show n + 2 = (n + 1) + 1 by ring]
      have hcast : (∑ i ∈ Finset.range (n + 1 + 1), ((n + 1).choose i : ℕ) ^ 2 : ℕ)
          = ((2 * (n + 1)).choose (n + 1) : ℕ) := this
      calc ∑ k ∈ Finset.range (n + 1 + 1), (((n + 1).choose k : ℕ) : ℤ) ^ 2
          = ((∑ k ∈ Finset.range (n + 1 + 1), ((n + 1).choose k : ℕ) ^ 2 : ℕ) : ℤ) := by
            push_cast; rfl
        _ = (((2 * (n + 1)).choose (n + 1) : ℕ) : ℤ) := by rw [hcast]
    rw [key]
    congr 2
  -- binom(2n+2, n+1) = 2 * binom(2n+1, n)
  have hpascal : ((2 * n + 2).choose (n + 1) : ℕ) = 2 * ((2 * n + 1).choose n : ℕ) := by
    have h1 : (2 * n + 2).choose (n + 1) = (2 * n + 1).choose n + (2 * n + 1).choose (n + 1) := by
      rw [show 2 * n + 2 = (2 * n + 1) + 1 by ring]
      rw [Nat.choose_succ_succ (2 * n + 1) n]
    have h2 : (2 * n + 1).choose (n + 1) = (2 * n + 1).choose n := by
      have := Nat.choose_symm_half n
      simpa using this
    rw [h1, h2]; ring
  -- Now combine. 2*L = L + S (from hLS) = (n+1)*binom(2n+2,n+1)
  have h2L : 2 * L = ((n : ℤ) + 1) * ((2 * n + 2).choose (n + 1) : ℕ) := by
    have : L + S = 2 * L := by rw [hLS]; ring
    rw [← this, hLpS]
  -- RHS: (n+1)*binom(2n+2,n+1) - (n+1)*binom(2n+1,n)
  -- using hpascal: binom(2n+2,n+1) = 2*binom(2n+1,n)
  have hpc : (((2 * n + 2).choose (n + 1) : ℕ) : ℤ) = 2 * (((2 * n + 1).choose n : ℕ) : ℤ) := by
    rw [hpascal]; push_cast; ring
  -- 2 * RHS = (n+1)*binom(2n+2,n+1)
  have h2R : 2 * (((n : ℤ) + 1) * ((2 * n + 2).choose (n + 1) : ℕ) - ((n : ℤ) + 1) * ((2 * n + 1).choose n : ℕ))
      = ((n : ℤ) + 1) * ((2 * n + 2).choose (n + 1) : ℕ) := by
    rw [hpc]; ring
  -- conclude: 2*L = 2*RHS, so L = RHS
  have : (2 : ℤ) * L = 2 * (((n : ℤ) + 1) * ((2 * n + 2).choose (n + 1) : ℕ) - ((n : ℤ) + 1) * ((2 * n + 1).choose n : ℕ)) := by
    rw [h2L, h2R]
  have hfin := mul_left_cancel₀ (by norm_num : (2 : ℤ) ≠ 0) this
  rw [hL] at hfin
  exact hfin