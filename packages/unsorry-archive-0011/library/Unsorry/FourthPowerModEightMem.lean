import Mathlib.Data.Nat.ModEq

-- This module proves that for any natural number n, n^4 mod 8 is either 0 or 1.

theorem fourth_power_mod_eight_mem (n : ℕ) : n ^ 4 % 8 = 0 ∨ n ^ 4 % 8 = 1 := by
  -- We can use the fact that any natural number is congruent to 0, 1, 2, 3, 4, 5, 6, or 7 modulo 8.
  -- Then we check each case to see what n^4 mod 8 is.
  have h : n % 8 = 0 ∨ n % 8 = 1 ∨ n % 8 = 2 ∨ n % 8 = 3 ∨ n % 8 = 4 ∨ n % 8 = 5 ∨ n % 8 = 6 ∨ n % 8 = 7 := by
    omega
  rcases h with (h | h | h | h | h | h | h | h)
  -- Case 1: If n ≡ 0 mod 8, then n^4 ≡ 0 mod 8.
  · simp [h, Nat.pow_mod]
  -- Case 2: If n ≡ 1 mod 8, then n^4 ≡ 1 mod 8.
  · simp [h, Nat.pow_mod]
  -- Case 3: If n ≡ 2 mod 8, then n^4 ≡ 0 mod 8.
  · simp [h, Nat.pow_mod]
  -- Case 4: If n ≡ 3 mod 8, then n^4 ≡ 1 mod 8.
  · simp [h, Nat.pow_mod]
  -- Case 5: If n ≡ 4 mod 8, then n^4 ≡ 0 mod 8.
  · simp [h, Nat.pow_mod]
  -- Case 6: If n ≡ 5 mod 8, then n^4 ≡ 1 mod 8.
  · simp [h, Nat.pow_mod]
  -- Case 7: If n ≡ 6 mod 8, then n^4 ≡ 0 mod 8.
  · simp [h, Nat.pow_mod]
  -- Case 8: If n ≡ 7 mod 8, then n^4 ≡ 1 mod 8.
  · simp [h, Nat.pow_mod]