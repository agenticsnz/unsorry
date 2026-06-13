import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic

theorem three_dvd_all_of_sq_add_sq_eq_three_mul_sq (x y z : ℤ)
    (h : x ^ 2 + y ^ 2 = 3 * z ^ 2) : 3 ∣ x ∧ 3 ∣ y ∧ 3 ∣ z := by
  have hmod : (x : ZMod 3) ^ 2 + (y : ZMod 3) ^ 2 = 0 := by
    have hc : (x : ZMod 3) ^ 2 + (y : ZMod 3) ^ 2 = 3 * (z : ZMod 3) ^ 2 := by
      have hcast := congrArg (fun t : ℤ => (t : ZMod 3)) h
      push_cast at hcast
      exact hcast
    rw [hc, show (3 : ZMod 3) = 0 from by decide, zero_mul]
  have key : ∀ a b : ZMod 3, a ^ 2 + b ^ 2 = 0 → a = 0 ∧ b = 0 := by decide
  obtain ⟨hx0, hy0⟩ := key _ _ hmod
  have hx3 : (3 : ℤ) ∣ x := by exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd x 3).mp hx0
  have hy3 : (3 : ℤ) ∣ y := by exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd y 3).mp hy0
  refine ⟨hx3, hy3, ?_⟩
  obtain ⟨a, rfl⟩ := hx3
  obtain ⟨b, rfl⟩ := hy3
  have h3 : (3 : ℤ) * z ^ 2 = 3 * (3 * (a ^ 2 + b ^ 2)) := by linear_combination -h
  have hz2 : z ^ 2 = 3 * (a ^ 2 + b ^ 2) := mul_left_cancel₀ (by norm_num) h3
  exact Int.prime_three.dvd_of_dvd_pow ⟨a ^ 2 + b ^ 2, hz2⟩
