import Mathlib.Data.Nat.Prime.Basic

/-!
# A natural number whose square is twice another square is itself a multiple of two

If `a ^ 2 = 2 * b ^ 2` then `2` divides `a`. From the hypothesis, `2` divides
`a ^ 2`; since `2` is prime, it must already divide the base `a`.
-/

theorem square_eq_two_mul_square_left_even (a b : ℕ) (h : a ^ 2 = 2 * b ^ 2) : 2 ∣ a := by
  have hdvd : 2 ∣ a ^ 2 := ⟨b ^ 2, h⟩
  exact Nat.Prime.dvd_of_dvd_pow Nat.prime_two hdvd
