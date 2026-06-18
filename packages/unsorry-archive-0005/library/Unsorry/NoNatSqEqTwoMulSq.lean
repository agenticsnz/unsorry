import Unsorry.NoNatSqEqTwoMulSqS1
import Unsorry.NoNatSqEqTwoMulSqS2
import Unsorry.NoNatSqEqTwoMulSqS3
import Unsorry.NoNatSqEqTwoMulSqS4

theorem no_nat_sq_eq_two_mul_sq : ¬ ∃ a b : ℕ, 0 < b ∧ a ^ 2 = 2 * b ^ 2 := by
  classical
  rintro ⟨a, b, hbpos, hsq⟩
  let P : ℕ → Prop := fun n => ∃ a : ℕ, 0 < n ∧ a ^ 2 = 2 * n ^ 2
  have hPb : P b := ⟨a, hbpos, hsq⟩
  let m := Nat.find ⟨b, hPb⟩
  have hmP : P m := Nat.find_spec ⟨b, hPb⟩
  obtain ⟨x, hmpos, hxm⟩ := hmP
  obtain ⟨c, hc⟩ := square_eq_two_mul_square_left_even x m hxm
  obtain ⟨d, hd⟩ := square_eq_two_mul_square_right_even x m hxm
  have hhalf : c ^ 2 = 2 * d ^ 2 :=
    square_eq_two_mul_square_halves x m c d hc hd hxm
  have hdposlt : 0 < d ∧ d < m := positive_half_lt_of_even_nat m d hmpos hd
  have hdlt : d < Nat.find ⟨b, hPb⟩ := by
    simpa [m] using hdposlt.2
  exact (Nat.find_min ⟨b, hPb⟩ hdlt) ⟨c, hdposlt.1, hhalf⟩
