import Mathlib

theorem sum_odd_gnomon_squares_closed_form (n : ℕ) : 2 * ∑ k ∈ Finset.range (n + 1), (3 * k - 2) ^ 2 = n * (6 * n ^ 2 - 3 * n - 1) := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, Nat.mul_add, ih]
    -- term: (3*(m+1) - 2)^2 = (3*m+1)^2
    have h1 : 3 * (m + 1) - 2 = 3 * m + 1 := by omega
    rw [h1]
    -- Now prove: m*(6*m^2-3*m-1) + 2*(3*m+1)^2 = (m+1)*(6*(m+1)^2-3*(m+1)-1)
    -- handle truncated subtraction by nlinarith on the cleared form
    have e1 : 6 * m ^ 2 ≥ 3 * m + 1 ∨ m = 0 := by
      rcases Nat.eq_zero_or_pos m with hm | hm
      · right; exact hm
      · left; nlinarith
    rcases e1 with e1 | e1
    · have e2 : 6 * (m + 1) ^ 2 ≥ 3 * (m + 1) + 1 := by nlinarith
      -- rewrite subtractions as additions via omega-friendly facts
      have lhsub : 6 * m ^ 2 - 3 * m - 1 = 6 * m ^ 2 - (3 * m + 1) := by omega
      have rhsub : 6 * (m + 1) ^ 2 - 3 * (m + 1) - 1 = 6 * (m + 1) ^ 2 - (3 * (m + 1) + 1) := by omega
      rw [lhsub, rhsub]
      have lpos : 6 * m ^ 2 - (3 * m + 1) + (3 * m + 1) = 6 * m ^ 2 := by omega
      have rpos : 6 * (m + 1) ^ 2 - (3 * (m + 1) + 1) + (3 * (m + 1) + 1) = 6 * (m + 1) ^ 2 := by omega
      -- prove equality by multiplying out; use Nat.sub bridging
      zify [e1, e2]
      ring
    · subst e1
      decide