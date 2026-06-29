import Mathlib

open Finset

theorem sum_range_odd_index_choose_eq_two_pow (n : ℕ) : ∑ k ∈ Finset.range (n + 1), (2 * (n + 1)).choose (2 * k + 1) = 2 ^ (2 * n + 1) := by
  -- helper: split range (2m+3) into even part (range m+2) + odd part (range m+1)
  have split : ∀ (f : ℕ → ℤ) (m : ℕ),
      ∑ j ∈ range (2 * m + 3), f j
        = (∑ k ∈ range (m + 2), f (2 * k)) + ∑ k ∈ range (m + 1), f (2 * k + 1) := by
    intro f m
    induction m with
    | zero =>
      simp only [Finset.sum_range_succ, Finset.sum_range_zero]
      ring
    | succ m ih =>
      have e : 2 * (m + 1) + 3 = (2 * m + 3) + 1 + 1 := by ring
      have hev : (∑ k ∈ range (m + 1 + 2), f (2 * k))
          = (∑ k ∈ range (m + 2), f (2 * k)) + f (2 * (m + 2)) := by
        rw [show m + 1 + 2 = (m + 2) + 1 from rfl, Finset.sum_range_succ]
      have hod : (∑ k ∈ range (m + 1 + 1), f (2 * k + 1))
          = (∑ k ∈ range (m + 1), f (2 * k + 1)) + f (2 * (m + 1) + 1) := by
        rw [Finset.sum_range_succ]
      rw [hev, hod, e, Finset.sum_range_succ, Finset.sum_range_succ, ih]
      ring_nf
  -- it suffices to prove the ℤ-cast statement
  have key : (∑ k ∈ range (n + 1), ((2 * (n + 1)).choose (2 * k + 1) : ℤ)) = 2 ^ (2 * n + 1) := by
    -- full sum over range (2*(n+1)+1) = range (2n+3)
    have hfull : (∑ j ∈ range (2 * (n + 1) + 1), ((2 * (n + 1)).choose j : ℤ))
        = 2 ^ (2 * (n + 1)) := by
      have := Nat.sum_range_choose (2 * (n + 1))
      calc (∑ j ∈ range (2 * (n + 1) + 1), ((2 * (n + 1)).choose j : ℤ))
          = ((∑ j ∈ range (2 * (n + 1) + 1), (2 * (n + 1)).choose j : ℕ) : ℤ) := by
            push_cast; rfl
        _ = ((2 ^ (2 * (n + 1)) : ℕ) : ℤ) := by rw [this]
        _ = 2 ^ (2 * (n + 1)) := by push_cast; ring
    -- apply split to the full sum
    have hsplitfull := split (fun j => ((2 * (n + 1)).choose j : ℤ)) n
    have hrange : 2 * n + 3 = 2 * (n + 1) + 1 := by ring
    rw [hrange] at hsplitfull
    -- so full = even + odd
    rw [hfull] at hsplitfull
    -- alternating sum = 0
    have halt : (∑ j ∈ range (2 * (n + 1) + 1), ((-1) ^ j * ((2 * (n + 1)).choose j : ℤ)))
        = 0 := by
      have := Int.alternating_sum_range_choose_of_ne (n := 2 * (n + 1)) (by positivity)
      simpa using this
    have hsplitalt := split (fun j => ((-1) ^ j * ((2 * (n + 1)).choose j : ℤ))) n
    rw [hrange] at hsplitalt
    rw [halt] at hsplitalt
    -- simplify the parity signs in the alternating split
    -- (-1)^(2k) = 1, (-1)^(2k+1) = -1
    have hevsign : ∀ k, ((-1 : ℤ)) ^ (2 * k) = 1 := by
      intro k; rw [pow_mul]; norm_num
    have hodsign : ∀ k, ((-1 : ℤ)) ^ (2 * k + 1) = -1 := by
      intro k; rw [pow_succ, pow_mul]; norm_num
    simp only [hevsign, hodsign, one_mul, neg_one_mul] at hsplitalt
    -- now: hsplitfull : 2^(2(n+1)) = EVEN + ODD
    --      hsplitalt  : 0 = EVEN + (-ODD)  i.e. 0 = EVEN - ODD
    set EVEN := ∑ k ∈ range (n + 2), ((2 * (n + 1)).choose (2 * k) : ℤ) with hE
    set ODD := ∑ k ∈ range (n + 1), ((2 * (n + 1)).choose (2 * k + 1) : ℤ) with hO
    -- hsplitalt has the odd part with a negation per-term; rewrite to -ODD
    have hODneg : (∑ k ∈ range (n + 1), -((2 * (n + 1)).choose (2 * k + 1) : ℤ)) = -ODD := by
      rw [hO, Finset.sum_neg_distrib]
    rw [hODneg] at hsplitalt
    -- linear algebra: ODD = 2^(2n+1)
    have hodd_val : ODD = 2 ^ (2 * n + 1) := by
      have h1 : EVEN + ODD = 2 ^ (2 * (n + 1)) := hsplitfull.symm
      have h2 : EVEN + -ODD = 0 := hsplitalt.symm
      have heq : (2 : ℤ) * ODD = 2 ^ (2 * (n + 1)) := by linarith
      have hpow : (2 : ℤ) ^ (2 * (n + 1)) = 2 * 2 ^ (2 * n + 1) := by
        have he : 2 * (n + 1) = (2 * n + 1) + 1 := by ring
        rw [he, pow_succ']
      rw [hpow] at heq
      linarith
    rw [hodd_val]
  -- cast back to ℕ
  have hcast : ((∑ k ∈ range (n + 1), (2 * (n + 1)).choose (2 * k + 1) : ℕ) : ℤ)
      = ((2 ^ (2 * n + 1) : ℕ) : ℤ) := by
    push_cast
    exact key
  exact_mod_cast hcast