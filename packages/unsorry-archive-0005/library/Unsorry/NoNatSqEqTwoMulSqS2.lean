import Mathlib.Data.Nat.Prime.Basic
import Mathlib.Tactic.Ring

/-!
# A square equal to twice a square forces an even factor

If `a ^ 2 = 2 * b ^ 2` for natural numbers `a` and `b`, then `b` is even.
The argument runs through primality of `2`: it divides `a`, hence `4 ∣ a ^ 2`,
which after cancelling a factor of `2` shows `2 ∣ b ^ 2` and therefore `2 ∣ b`.
-/

theorem square_eq_two_mul_square_right_even (a b : ℕ) (h : a ^ 2 = 2 * b ^ 2) :
    2 ∣ b := by
  have hp : Nat.Prime 2 := Nat.prime_two
  have h2a : 2 ∣ a := hp.dvd_of_dvd_pow (show 2 ∣ a ^ 2 from ⟨b ^ 2, h⟩)
  obtain ⟨c, rfl⟩ := h2a
  have hb : b ^ 2 = 2 * c ^ 2 := by
    have hexp : 2 * b ^ 2 = 2 * (2 * c ^ 2) := by rw [← h]; ring
    omega
  exact hp.dvd_of_dvd_pow (show 2 ∣ b ^ 2 from ⟨c ^ 2, hb⟩)
